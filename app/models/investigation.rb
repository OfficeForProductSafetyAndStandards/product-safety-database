class Investigation < ApplicationRecord
  extend Pagy::Searchkick

  include Documentable
  include SanitizationHelper
  include InvestigationSearchkick
  include Deletable

  attr_accessor :visibility_rationale, :owner_rationale

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
    not_conclusive: "not_conclusive",
    other: "other"
  }

  enum corrective_action_taken: {
    yes: "yes",
    referred_to_another_authority: "referred_to_another_authority",
    not_enough_information: "not_enough_information",
    other: "other"
  }, _prefix: true

  before_validation { trim_line_endings(:user_title, :non_compliant_reason, :hazard_description, :corrective_action_not_taken_reason) }

  validates :type, presence: true # Prevent saving instances of Investigation; must use a subclass instead

  validates :user_title, length: { maximum: 100 }
  validates :description, length: { maximum: 10_000 }
  validates :non_compliant_reason, length: { maximum: 10_000 }
  validates :hazard_description, length: { maximum: 10_000 }
  validates :corrective_action_not_taken_reason, length: { maximum: 100 }

  has_many :investigation_products, dependent: :destroy
  has_many :products, through: :investigation_products

  has_many :investigation_businesses, dependent: :destroy
  has_many :businesses, through: :investigation_businesses

  has_many :activities, -> { order(created_at: :desc) }, dependent: :destroy, inverse_of: :investigation

  has_many :corrective_actions, dependent: :destroy
  has_many :correspondences, dependent: :destroy
  has_many :emails, dependent: :destroy, class_name: "Correspondence::Email"
  has_many :phone_calls, dependent: :destroy, class_name: "Correspondence::PhoneCall"

  has_many :tests, dependent: :destroy
  has_many :test_results, class_name: "Test::Result", dependent: :destroy

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

  has_many :risk_assessments, dependent: :destroy
  has_many :prism_associated_investigations
  has_many :prism_risk_assessments, through: :prism_associated_investigations
  has_many :accidents
  has_many :incidents
  has_many :unexpected_events

  scope :not_private, -> { where(is_private: false) }

  redacted_export_with :id, :complainant_reference, :coronavirus_related, :created_at, :custom_risk_level,
                       :date_closed, :date_received, :description, :hazard_description, :hazard_type,
                       :is_closed, :is_private, :non_compliant_reason, :notifying_country, :pretty_id,
                       :product_category, :received_type, :reported_reason, :risk_level, :risk_validated_at,
                       :risk_validated_by, :type, :updated_at, :user_title, :deleted_at, :deleted_by

  self.ignored_columns += %w[ahoy_visit_id]

  # All sub-classes share this policy class
  def self.policy_class
    InvestigationPolicy
  end

  def initialize(*args)
    raise "Cannot instantiate an Investigation - use one of its subclasses instead" if instance_of?(Investigation)

    super
  end

  def owner
    owner_user || owner_team
  end

  def owner_id
    owner&.id
  end

  def non_owner_teams_with_access
    teams_with_read_only_access.or(teams_with_edit_access).order(:name) - [owner.team]
  end

  def non_owner_collaborators_with_access
    collaboration_accesses.sorted_by_team_name - [owner_team_collaboration]
  end

  def build_owner_collaborations_from(user)
    build_owner_user_collaboration(collaborator: user)
    build_owner_team_collaboration(collaborator: user.team)
    self
  end

  # Legacy images that were uploaded as an attachment
  def images
    @images ||= documents
      .includes(:blob)
      .joins(:blob)
      .where("left(content_type, 5) = 'image'")
      .where.not(record: [corrective_actions, correspondences, tests])
  end

  def number_of_related_images
    images.size + image_uploads.size
  end

  def generic_supporting_information_attachments
    @generic_supporting_information_attachments ||= documents
      .includes(:blob)
      .joins(:blob)
      .where.not("left(content_type, 5) = 'image'")
      .where.not(record: [corrective_actions, correspondences, tests])
  end

  def supporting_information
    @supporting_information ||= (corrective_actions + correspondences + test_results.includes(:investigation_product) + risk_assessments + prism_risk_assessments + accidents + incidents).sort_by(&:created_at).reverse
  end

  # Expose image uploads similarly to other model attributes while managing them as an
  # array of IDs. This allows investigations to be versioned along with their associated image
  # uploads as they were at the time of the versioned investigation.
  def image_uploads
    ImageUpload.where(id: image_upload_ids)
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

  def sends_notifications?
    !is_closed
  end

private

  def creator_id
    creator_user&.id
  end
end

require_dependency "investigation/allegation"
require_dependency "investigation/project"
require_dependency "investigation/enquiry"
