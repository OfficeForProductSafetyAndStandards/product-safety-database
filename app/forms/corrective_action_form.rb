class CorrectiveActionForm
  include ActiveModel::Model
  include ActiveModel::Attributes
  include ActiveModel::Serialization
  include ActiveModel::Validations::Callbacks
  include ActiveModel::Dirty
  include SanitizationHelper
  include HasDocumentAttachedConcern

  attr_accessor :date_decided_year, :date_decided_month, :date_decided_day

  attribute :id
  attribute :date_decided, :govuk_date
  attribute "date_decided(1i)"
  attribute "date_decided(2i)"
  attribute "date_decided(3i)"
  attribute :investigation_product_id, :integer
  attribute :business_id, :integer
  attribute :legislation, default: []
  attribute :action
  attribute :details
  attribute :related_file
  attribute :measure_type
  attribute :duration
  attribute :geographic_scopes
  attribute :other_action
  attribute :has_online_recall_information, default: nil
  attribute :online_recall_information
  attribute :related_file, :boolean
  alias_method :related_file?, :related_file
  attribute :document
  attribute :existing_document_file_id
  attribute :filename
  attribute :file_description
  attribute :further_corrective_action, :boolean

  validates :action, inclusion: { in: CorrectiveAction.actions.keys }
  validates :investigation_product_id, presence: true, on: %i[add_corrective_action edit_corrective_action]
  validates :date_decided,
            presence: true,
            real_date: true,
            complete_date: true,
            recent_date: true
  validates :legislation, presence: { message: "Select the legislation relevant to the corrective action" }
  validates :has_online_recall_information, inclusion: { in: CorrectiveAction.has_online_recall_informations.keys }
  validate :online_recall_information_validation
  validates :further_corrective_action, inclusion: { in: [true, false] }, on: :ts_flow
  validates :measure_type, presence: true
  validates :measure_type, inclusion: { in: CorrectiveAction::MEASURE_TYPES }, if: -> { measure_type.present? }
  validates :duration, presence: true
  validates :duration, inclusion: { in: CorrectiveAction::DURATION_TYPES }, if: -> { duration.present? }
  validates :geographic_scopes, presence: true
  validate :geographic_scopes_inclusion
  validates :other_action, presence: true, length: { maximum: 10_000 }, if: :other?
  validates :other_action, absence: true, unless: :other?
  validates :details, length: { maximum: 32_767 }
  validates :related_file, inclusion: { in: [true, false], message: "Select whether you want to upload a related file" }
  validate :related_file_attachment_validation

  before_validation { trim_whitespace(:other_action, :details, :file_description, :online_recall_information) }
  before_validation { nilify_blanks(:other_action, :details, :online_recall_information) }
  before_validation :clear_related_file, unless: :related_file
  before_validation :clear_other_action, unless: -> { other? }

  ATTRIBUTES_FROM_CORRECTIVE_ACTION = %i[
    id
    date_decided
    investigation_product_id
    business_id
    legislation
    action
    details
    measure_type
    duration
    geographic_scopes
    other_action
    online_recall_information
    has_online_recall_information
  ].freeze

  def self.from(corrective_action)
    new(corrective_action.serializable_hash(only: ATTRIBUTES_FROM_CORRECTIVE_ACTION)).tap do |corrective_action_form|
      if corrective_action.document.attached?
        corrective_action_form.existing_document_file_id = corrective_action.document.signed_id
        corrective_action_form.load_document_file
        corrective_action_form.related_file = true
      else
        corrective_action_form.related_file = false
      end
      corrective_action_form.changes_applied
    end
  end

  def initialize(attributes = {})
    super
    self.online_recall_information = nil unless has_online_recall_information_yes?
    @date_decided_year = attributes["date_decided(1i)"]
    @date_decided_month = attributes["date_decided(2i)"]
    @date_decided_day = attributes["date_decided(3i)"]
  end

  def file=(document_params)
    return unless related_file

    assign_file_and_description(document_params)
  end

private

  def set_date
    { year: @date_decided_year, month: @date_decided_month, day: @date_decided_day }
  end

  def other?
    (action || "").inquiry.other?
  end

  def related_file_attachment_validation
    if related_file && document.nil?
      errors.add(:related_file, :file_missing, message: "Provide a related file or select no")
    end
  end

  def online_recall_information_validation
    if has_online_recall_information_yes? && online_recall_information.blank?
      errors.add(:online_recall_information, :blank)
    end
  end

  def has_online_recall_information_yes?
    has_online_recall_information == CorrectiveAction.has_online_recall_informations["has_online_recall_information_yes"]
  end

  def clear_related_file
    self.existing_document_file_id = nil
    self.filename = nil
    self.file_description = nil
  end

  def geographic_scopes_inclusion
    unless geographic_scopes.all? { |geographic_scope| CorrectiveAction::GEOGRAPHIC_SCOPES.include?(geographic_scope) }
      errors.add(:geographic_scopes, :inclusion)
    end
  end

  def clear_other_action
    self.other_action = nil
  end
end
