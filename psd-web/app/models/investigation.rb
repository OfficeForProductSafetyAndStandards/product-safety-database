class Investigation < ApplicationRecord
  include Documentable
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

  validates :type, presence: true # Prevent saving instances of Investigation; must use a subclass instead

  validates :description, presence: true, on: :update

  validates :user_title, length: { maximum: 100 }
  validates :description, length: { maximum: 10_000 }
  validates :non_compliant_reason, length: { maximum: 10_000 }
  validates :hazard_description, length: { maximum: 10_000 }

  after_update :create_audit_activity_for_status,
               :create_audit_activity_for_visibility,
               :create_audit_activity_for_summary

  default_scope { order(updated_at: :desc) }

  has_many :investigation_products, dependent: :destroy
  has_many :products, through: :investigation_products

  has_many :investigation_businesses, dependent: :destroy
  has_many :businesses,
           through: :investigation_businesses,
           after_add: :create_audit_activity_for_business,
           after_remove: :create_audit_activity_for_removing_business

  has_many :activities, -> { order(created_at: :desc) }, dependent: :destroy, inverse_of: :investigation

  has_many :corrective_actions, dependent: :destroy
  has_many :correspondences, dependent: :destroy
  has_many :emails, dependent: :destroy, class_name: "Correspondence::Email"
  has_many :phone_calls, dependent: :destroy, class_name: "Correspondence::PhoneCall"
  has_many :meetings, dependent: :destroy, class_name: "Correspondence::Meeting"

  has_many :tests, dependent: :destroy
  has_many :test_results, class_name: "Test::Result", dependent: :destroy
  has_many :alerts, dependent: :destroy

  has_many_attached :documents

  has_one :complainant, dependent: :destroy

  has_many :edit_access_collaborations, dependent: :destroy, class_name: "Collaboration::Access::Edit"
  has_many :teams_with_edit_access, through: :edit_access_collaborations, dependent: :destroy, source: :editor, source_type: "Team"

  has_many :read_only_collaborations, class_name: "Collaboration::Access::ReadOnly"

  has_one :creator_user_collaboration, dependent: :destroy, class_name: "Collaboration::CreatorUser"
  has_one :creator_team_collaboration, dependent: :destroy, class_name: "Collaboration::CreatorTeam"
  has_one :creator_team, through: :creator_team_collaboration, dependent: :destroy, source_type: "Team"
  has_one :creator_user, through: :creator_user_collaboration, dependent: :destroy, source_type: "User"

  has_one :owner_user_collaboration, dependent: :destroy, class_name: "Collaboration::OwnerUser"
  has_one :owner_team_collaboration, dependent: :destroy, class_name: "Collaboration::OwnerTeam"
  has_one :owner_team, through: :owner_team_collaboration, dependent: :destroy, source_type: "Team", required: true
  has_one :owner_user, through: :owner_user_collaboration, dependent: :destroy, source_type: "User"

  def initialize(*args)
    raise "Cannot instantiate an Investigation - use one of its subclasses instead" if self.class == Investigation

    super
  end

  def owner
    owner_user || owner_team
  end

  def owner_id
    owner&.id
  end

  def owner=(team_or_user)
    if team_or_user.is_a? User
      self.owner_user = team_or_user
      self.owner_team = team_or_user.team
    elsif team_or_user.is_a? Team
      self.owner_team = team_or_user
      self.owner_user = nil
    end
  end

  def images
    @images ||= documents
      .includes(:blob)
      .joins(:blob)
      .where("left(content_type, 5) = 'image'")
      .where.not(record: [corrective_actions, correspondences, tests])
  end

  def generic_supporting_information_attachments
    @generic_supporting_information_attachments ||= documents
      .includes(:blob)
      .joins(:blob)
      .where.not("left(content_type, 5) = 'image'")
      .where.not(record: [corrective_actions, correspondences, tests])
  end

  def supporting_information
    @supporting_information ||= (corrective_actions + correspondences + test_results.includes(:product)).sort_by(&:created_at).reverse
  end

  def teams_with_access
    ([owner_team] + teams_with_edit_access.sort_by(&:name)).compact
  end

  def status
    is_closed? ? "Closed" : "Open"
  end

  def important_owner_people
    people = [].to_set
    people << owner if owner.is_a? User
    people << User.current
    people
  end

  def past_owners
    activities = AuditActivity::Investigation::UpdateOwner.where(investigation_id: id)
    activities.map(&:owner)
  end

  def important_owner_teams
    teams = [User.current.team].to_set

    Team.get_visible_teams(User.current).each do |team|
      teams << team
    end
    teams << owner if owner.is_a? Team
    teams
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
    return if self[:reported_reason].blank?

    @reported_reason ||= ActiveSupport::StringInquirer.new(self[:reported_reason])
  end

  def case_created_audit_activity_class
    # To be implemented by children
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

  def create_audit_activity_for_summary
    # TODO: User.current check is here to avoid triggering activity and emails from migrations
    # Can be safely removed once the migration PopulateAssigneeAndDescription has run
    if saved_changes.key?(:description) && User.current
      AuditActivity::Investigation::UpdateSummary.from(self)
    end
  end

  def create_audit_activity_for_business(business)
    AuditActivity::Business::Add.from(business, self)
  end

  def create_audit_activity_for_removing_business(business)
    AuditActivity::Business::Destroy.from(business, self)
  end

  def creator_id
    creator_user&.id
  end
end

require_dependency "investigation/allegation"
require_dependency "investigation/project"
require_dependency "investigation/enquiry"
