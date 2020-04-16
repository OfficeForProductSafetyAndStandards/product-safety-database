class Investigation < ApplicationRecord
  include Documentable
  include AttachmentConcern
  include SanitizationHelper
  include InvestigationElasticsearch

  attr_accessor :status_rationale
  attr_accessor :visibility_rationale
  attr_accessor :assignee_rationale

  enum reported_reason: {
         unsafe: "unsafe",
         non_compliant: "non_compliant",
         unsafe_and_non_compliant: "unsafe_and_non_compliant",
         safe_and_compliant: "safe_and_compliant"
       }

  before_validation { trim_line_endings(:user_title, :description, :non_compliant_reason, :hazard_description) }

  validates :description, presence: true, on: :update
  validates :assignable_id, presence: { message: "Select assignee" }, on: :update

  validates_length_of :user_title, maximum: 100
  validates_length_of :description, maximum: 10000
  validates_length_of :non_compliant_reason, maximum: 10000
  validates_length_of :hazard_description, maximum: 10000

  after_update :create_audit_activity_for_assignee, :create_audit_activity_for_status,
               :create_audit_activity_for_visibility, :create_audit_activity_for_summary

  default_scope { order(updated_at: :desc) }

  belongs_to :assignable, polymorphic: true, optional: true

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

  has_one :source, as: :sourceable, dependent: :destroy
  has_one :complainant, dependent: :destroy

  has_many :collaborators, dependent: :destroy
  has_many :teams, through: :collaborators

  # TODO: Refactor to remove this callback hell
  before_create :set_source_to_current_user, :assign_to_current_user, :add_pretty_id
  after_create :create_audit_activity_for_case, :send_confirmation_email

  def assignee_team
    assignable&.team
  end

  def teams_with_access
    ([assignee_team] + teams.order(:name)).compact
  end

  def status
    is_closed? ? "Closed" : "Open"
  end

  def pretty_visibility
    is_private ? ApplicationController.helpers.visibility_options[:private] : ApplicationController.helpers.visibility_options[:public]
  end

  def important_assignable_people
    people = [].to_set
    people << assignable if assignable.is_a? User
    people << User.current
    people
  end

  def past_assignees
    activities = AuditActivity::Investigation::UpdateAssignee.where(investigation_id: id)
    user_id_list = activities.map(&:assignable_id)
    User.where(id: user_id_list)
  end

  def important_assignable_teams
    teams = User.current.teams.to_set
    Team.get_visible_teams(User.current).each do |team|
      teams << team
    end
    teams << assignable if assignable.is_a? Team
    teams
  end

  def past_teams
    activities = AuditActivity::Investigation::UpdateAssignee.where(investigation_id: id)
    team_id_list = activities.map(&:assignable_id)
    Team.where(id: team_id_list)
  end

  def enquiry?
    self.is_a?(Investigation::Enquiry)
  end

  def allegation?
    self.is_a?(Investigation::Allegation)
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

  def add_pretty_id
    cases_before = Investigation.where("created_at < ? AND created_at > ?", created_at, created_at.beginning_of_month).count
    self.pretty_id = "#{created_at.strftime('%y%m')}-%04d" % (cases_before + 1)
  end

  def child_should_be_displayed?
    # This method is responsible for white-list access for assignee and their team, as described in
    # https://regulatorydelivery.atlassian.net/wiki/spaces/PSD/pages/598933517/Approach+to+case+sensitivity
    assignable.in_same_team_as?(User.current)
  end

private

  def create_audit_activity_for_case
    # To be implemented by children
  end

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

  def create_audit_activity_for_assignee
    # TODO: User.current check is here to avoid triggering activity and emails from migrations
    # Can be safely removed once the migration PopulateAssigneeAndDescription has run
    if ((saved_changes.key? :assignable_id) || (saved_changes.key? :assignable_type)) && User.current
      AuditActivity::Investigation::UpdateAssignee.from(self)
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

  def set_source_to_current_user
    self.source = UserSource.new(user: User.current) if source.blank? && User.current
  end

  def creator_id
    self.source&.user_id
  end

  def assign_to_current_user
    self.assignable = User.current if assignable.blank? && User.current
  end

  # TODO: Refactor to remove dependency on User.current
  def send_confirmation_email
    if User.current
      NotifyMailer.investigation_created(
        pretty_id,
        User.current.name,
        User.current.email,
        self.decorate.title,
        case_type
      ).deliver_later
    end
  end
end

require_dependency "investigation/allegation"
require_dependency "investigation/project"
require_dependency "investigation/enquiry"
