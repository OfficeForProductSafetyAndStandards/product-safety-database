class Investigation < ApplicationRecord
  include Documentable
  include SanitizationHelper
  include InvestigationElasticsearch

  attr_accessor :visibility_rationale
  attr_accessor :owner_rationale

  enum reported_reason: {
    unsafe: "unsafe",
    non_compliant: "non_compliant",
    unsafe_and_non_compliant: "unsafe_and_non_compliant",
    safe_and_compliant: "safe_and_compliant"
  }

  enum risk_level: {
    serious: "serious",
    high: "high",
    medium: "medium",
    low: "low",
    other: "other"
  }

  before_validation { trim_line_endings(:user_title, :non_compliant_reason, :hazard_description) }

  validates :type, presence: true # Prevent saving instances of Investigation; must use a subclass instead

  validates :description, presence: true, on: :update

  validates :user_title, length: { maximum: 100 }
  validates :description, length: { maximum: 10_000 }
  validates :non_compliant_reason, length: { maximum: 10_000 }
  validates :hazard_description, length: { maximum: 10_000 }
  validates :custom_risk_level, absence: true, if: -> { risk_level != "other" }
  validates :custom_risk_level, presence: true, if: -> { risk_level == "other" }

  after_update :create_audit_activity_for_visibility

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
  has_many :collaborations
  has_many :edit_access_collaborations, dependent: :destroy, class_name: "Collaboration::Access::Edit"
  has_many :teams_with_edit_access, through: :edit_access_collaborations, dependent: :destroy, source: :collaborator, source_type: "Team"

  has_many :read_only_collaborations, class_name: "Collaboration::Access::ReadOnly"
  has_many :teams_with_read_only_access, through: :read_only_collaborations, source: :collaborator, source_type: "Team"

  has_many :collaboration_accesses,   class_name: "Collaboration::Access"
  has_many :teams_with_access, lambda {
    select("teams.*, CASE collaborations.type WHEN 'Collaboration::Access::OwnerTeam' THEN 1 ELSE 2 END").distinct.joins(:collaborations).order(Arel.sql("CASE collaborations.type WHEN 'Collaboration::Access::OwnerTeam' THEN 1 ELSE 2 END, teams.name")).references(:collaborations)
  }, through: :collaboration_accesses, source: :collaborator, source_type: "Team"

  has_one :creator_user_collaboration, dependent: :destroy, class_name: "Collaboration::CreatorUser"
  has_one :creator_team_collaboration, dependent: :destroy, class_name: "Collaboration::CreatorTeam"
  has_one :creator_team, through: :creator_team_collaboration, dependent: :destroy, source_type: "Team"
  has_one :creator_user, through: :creator_user_collaboration, dependent: :destroy, source_type: "User"

  has_many :collaboration_access_owners, class_name: "Collaboration::Access::Owner"
  has_one :owner_user_collaboration, class_name: "Collaboration::Access::OwnerUser", dependent: :destroy, inverse_of: :investigation
  has_one :owner_team_collaboration, class_name: "Collaboration::Access::OwnerTeam", dependent: :destroy, required: true
  has_one :owner_team, through: :owner_team_collaboration, dependent: :destroy, source_type: "Team", source: :collaborator
  has_one :owner_user, through: :owner_user_collaboration, dependent: :destroy, source_type: "User", source: :collaborator

  has_many :risk_assessments
  has_many :accidents
  has_many :incidents
  has_many :unexpected_events

  # All sub-classes share this policy class
  def self.policy_class
    InvestigationPolicy
  end

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

  def build_owner_collaborations_from(user)
    build_owner_user_collaboration(collaborator: user)
    build_owner_team_collaboration(collaborator: user.team)
    self
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
    @supporting_information ||= (corrective_actions + correspondences + test_results.includes(:product) + risk_assessments + accidents + incidents).sort_by(&:created_at).reverse
  end

  def status
    is_closed? ? "Closed" : "Open"
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

    @reported_reason = ActiveSupport::StringInquirer.new(self[:reported_reason])
  end

  def case_created_audit_activity_class
    # To be implemented by children
  end

  def categories
    ([product_category] + products.map(&:category)).tap do |c|
      c.uniq!
      c.compact!
    end
  end

  def has_had_risk_level_validated_before?
    activities.where(type: "AuditActivity::Investigation::UpdateRiskLevelValidation").exists?
  end

  def risk_level_currently_validated?
    !risk_validated_by.nil?
  end

private

  def create_audit_activity_for_visibility
    if saved_changes.key?(:is_private) || visibility_rationale.present?
      AuditActivity::Investigation::UpdateVisibility.from(self)
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
