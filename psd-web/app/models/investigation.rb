class Investigation < ApplicationRecord
  include Documentable
  include AttachmentConcern
  include SanitizationHelper
  include InvestigationElasticsearch

  attr_accessor :status_rationale
  attr_accessor :visibility_rationale
  attr_accessor :owner_rationale

  enum reported_reason: {
    unsafe: "unsafe",
    non_compliant: "non_compliant",
    unsafe_and_non_compliant: "unsafe_and_non_compliant",
    safe_and_compliant: "safe_and_compliant"
  }

  before_validation { trim_line_endings(:user_title, :description, :non_compliant_reason, :hazard_description) }

  validates :description, presence: true, on: :update

  validates :user_title, length: { maximum: 100 }
  validates :description, length: { maximum: 10000 }
  validates :non_compliant_reason, length: { maximum: 10000 }
  validates :hazard_description, length: { maximum: 10000 }

  after_update :create_audit_activity_for_owner, :create_audit_activity_for_status,
               :create_audit_activity_for_visibility, :create_audit_activity_for_summary

  default_scope { order(updated_at: :desc) }

  has_many :investigation_products, dependent: :destroy
  has_many :products, through: :investigation_products,
                      after_add: :create_audit_activity_for_product,
                      after_remove: :create_audit_activity_for_removing_product

  has_many :investigation_businesses, dependent: :destroy
  has_many :businesses, through: :investigation_businesses,
                        after_add: :create_audit_activity_for_business,
                        after_remove: :create_audit_activity_for_removing_business

  has_many :activities, -> { order(created_at: :desc) }, dependent: :destroy, inverse_of: :investigation

  has_many :corrective_actions, dependent: :destroy
  has_many :correspondences, dependent: :destroy
  has_many :tests, dependent: :destroy
  has_many :alerts, dependent: :destroy

  has_many_attached :documents

  has_one :complainant, dependent: :destroy

  # any old collaborators
  has_many :historic_collaborators, class_name: "Collaborators::Historic", dependent: :destroy

  has_many :case_creators, class_name: "Collaborators::CaseCreator", dependent: :destroy
  # => add index to enforce CollaboratingType to be "Team"
  has_one :case_creator_team, class_name: "Collaborators::CaseCreatorTeam", dependent: :destroy, inverse_of: :investigation
  # => add index to enforce CollaboratingType to be "User"
  has_one :case_creator_user, class_name: "Collaborators::CaseCreatorUser", dependent: :destroy, inverse_of: :investigation

  has_many :case_owners, class_name: "Collaborators::CaseOwner", dependent: :destroy, inverse_of: :investigation
  # => add index to enforce (type, CollaboratingType) to be ("Collaborators::CaseOwnerTeam", "Team")
  has_one :case_owner_team, class_name: "Collaborators::CaseOwnerTeam", dependent: :destroy, inverse_of: :investigation
  # => add index to enforce (type, CollaboratingType) to be ("Collaborators::CaseOwnerUser, User")
  has_one :case_owner_user, class_name: "Collaborators::CaseOwnerUser", dependent: :destroy, inverse_of: :investigation

  has_many :collaborators, dependent: :destroy

  # scenario: assign a case to a user
  # 1. make user's team the CaseOwnerTeam
  # 2. make user's team the CaseOwnerUser
  # 3. previous CaseOwnerTeam => CoCollaborator
  # 4. previous CaseOwnerUser => Collaborator

  # investigation.owners => [CaseOwner, CaseCreator]
  # investigation.case_creator => CaseCreator
  # investigation.case_owner => CaseOwner || CaseCreator
  # Scenario 1: assigne back the case to the case creator
  # 1. move current case owner to a co_collaborators
  # investigation.case_owner => CaseCreator (sub type of CaseOwner so same behaviour)
  # Scenario 2: assigne to a new team
  # 1. move current case owner to a co_collaborators
  # 2. add the new team or user as the case owner
  # invesigation.case_owner => CaseOwer with new team or user
  # invesigation.co_collaborators => Old CaseOwner but now it is a CoCollaborator
  # invesigation.case_creator => not change
  # invesigation.owners => [CaseOwner, CaseCreator]
  # invesigation.collaborators => [CoColloaborator(former case owner), CaseOwner, CaseCreator]

  # temporary to retain the "owner id functionality"
  def owner_id
    case_owner_team.id || case_owner_user.id
  end

  # temporary backward compatibility
  def source
    case_creator_user || case_creator_team
  end

  def owner
    case_owner_user&.collaborating
  end

  def owner_team
    owner&.team
  end

  def teams_with_access
    collaborators.flat_map(&:collaborating)
  end

  def status
    is_closed? ? "Closed" : "Open"
  end

  def pretty_visibility
    is_private ? ApplicationController.helpers.visibility_options[:private] : ApplicationController.helpers.visibility_options[:public]
  end

  def important_owner_people
    people = [].to_set
    people << owner if owner.is_a? User
    people << User.current
    people
  end

  def past_owners
    activities = AuditActivity::Investigation::UpdateOwner.where(investigation_id: id)
    user_id_list = activities.map(&:owner_id)
    User.where(id: user_id_list)
  end

  def important_owner_teams
    teams = User.current.teams.to_set
    Team.get_visible_teams(User.current).each do |team|
      teams << team
    end
    teams << owner if owner.is_a? Team
    teams
  end

  def past_teams
    activities = AuditActivity::Investigation::UpdateOwner.where(investigation_id: id)
    team_id_list = activities.map(&:owner_id)
    Team.where(id: team_id_list)
  end

  def enquiry?
    is_a?(Investigation::Enquiry)
  end

  def allegation?
    is_a?(Investigation::Allegation)
  end

  # To be implemented by children
  def title; end

  def case_type; end

  def add_business(business, relationship)
    # Could not find a way to add a business to an investigation which allowed us to set the relationship value and
    # while still triggering the callback to add the audit activity. One possibility is to move the callback to the
    # InvestigationBusiness model.
    investigation_businesses.create!(business_id: business.id, relationship: relationship)
    create_audit_activity_for_business(business)
  end

  def to_param
    pretty_id
  end

  def reported_reason
    return if super.blank?

    @reported_reason ||= ActiveSupport::StringInquirer.new(super)
  end

  def child_should_be_displayed?
    # This method is responsible for white-list access for assignee and their team, as described in
    # https://regulatorydelivery.atlassian.net/wiki/spaces/PSD/pages/598933517/Approach+to+case+sensitivity
    owner.in_same_team_as?(User.current)
  end

private

  def create_audit_activity_for_status
    if saved_changes.key?(:is_closed) || status_rationale.present?
      AuditActivity::Investigation::UpdateStatus.from(self)
    end
  end

  def create_audit_activity_for_visibility
    if saved_changes.key?(:is_private) || visibility_rationale.present?
      AuditActivity::Investigation::UpdateVisibility.from(self)
    end
  end

  def create_audit_activity_for_owner
    # TODO: User.current check is here to avoid triggering activity and emails from migrations
    # Can be safely removed once the migration PopulateAssigneeAndDescription has run
    if ((saved_changes.key? :owner_id) || (saved_changes.key? :owner_type)) && User.current
      AuditActivity::Investigation::UpdateOwner.from(self)
    end
  end

  def create_audit_activity_for_summary
    # TODO: User.current check is here to avoid triggering activity and emails from migrations
    # Can be safely removed once the migration PopulateAssigneeAndDescription has run
    if saved_changes.key?(:description) && User.current
      AuditActivity::Investigation::UpdateSummary.from(self)
    end
  end

  def create_audit_activity_for_product(product)
    AuditActivity::Product::Add.from(product, self)
  end

  def create_audit_activity_for_removing_product(product)
    AuditActivity::Product::Destroy.from(product, self)
  end

  def create_audit_activity_for_business(business)
    AuditActivity::Business::Add.from(business, self)
  end

  def create_audit_activity_for_removing_business(business)
    AuditActivity::Business::Destroy.from(business, self)
  end

  def creator_id
    case_creator_team&.id
  end
end

require_dependency "investigation/allegation"
require_dependency "investigation/project"
require_dependency "investigation/enquiry"
