class CorrectiveActionForm
  include ActiveModel::Model
  include ActiveModel::Attributes
  include ActiveModel::Serialization
  include ActiveModel::Validations::Callbacks
  include ActiveModel::Dirty
  include SanitizationHelper
  include HasDocumentAttachedConcern

  attribute :id
  attribute :date_decided, :govuk_date
  attribute :product_id, :integer
  attribute :business_id, :integer
  attribute :legislation
  attribute :action
  attribute :details
  attribute :related_file
  attribute :measure_type
  attribute :duration
  attribute :geographic_scope
  attribute :other_action
  attribute :has_online_recall_information, :boolean, default: nil
  attribute :online_recall_information
  attribute :related_file, :boolean
  attribute :document
  attribute :existing_document_file_id
  attribute :filename
  attribute :file_description

  validates :date_decided,
            presence: true,
            real_date: true,
            complete_date: true,
            not_in_future: true
  validates :legislation, presence: { message: "Select the legislation relevant to the corrective action" }
  validates :related_file, inclusion: { in: [true, false], message: "Select whether you want to upload a related file" }
  validate :related_file_attachment_validation
  validates :has_online_recall_information, inclusion: { in: [true, false] }
  validate :online_recall_information_validation

  validates :measure_type, presence: true
  validates :measure_type, inclusion: { in: CorrectiveAction::MEASURE_TYPES }, if: -> { measure_type.present? }
  validates :duration, presence: true
  validates :duration, inclusion: { in: CorrectiveAction::DURATION_TYPES }, if: -> { duration.present? }
  validates :geographic_scope, presence: true
  validates :geographic_scope, inclusion: { in: Rails.application.config.corrective_action_constants["geographic_scope"] }, if: -> { geographic_scope.present? }
  validates :action, inclusion: { in: CorrectiveAction.actions.keys }
  validates :other_action, presence: true, length: { maximum: 10_000 }, if: :other?
  validates :other_action, absence: true, unless: :other?
  validates :details, length: { maximum: 50_000 }

  before_validation { trim_line_endings(:other_action, :details) }

  ATTRIBUTES_FROM_CORRECTIVE_ACTION = %i[
    id
    date_decided
    product_id
    business_id
    legislation
    action
    details
    measure_type
    duration
    geographic_scope
    other_action
    online_recall_information
    has_online_recall_information
  ].freeze

  def self.from(corrective_action)
    new(corrective_action.serializable_hash(only: ATTRIBUTES_FROM_CORRECTIVE_ACTION)).tap do |corrective_action_form|
      if corrective_action.document.attached?
        corrective_action_form.existing_document_file_id = corrective_action.document.signed_id
      end
      corrective_action_form.load_document_file
      corrective_action_form.changes_applied
    end
  end

  def file=(document_params)
    return unless related_file

    assign_file_and_description(document_params)
  end

private

  def other?
    (action || "").inquiry.other?
  end

  def related_file_attachment_validation
    if related_file && document.nil?
      errors.add(:related_file, :file_missing, message: "Provide a related file or select no")
    end
  end

  def online_recall_information_validation
    if has_online_recall_information && online_recall_information.blank?
      errors.add(:online_recall_information, :blank)
    end
  end
end
