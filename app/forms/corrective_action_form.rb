class CorrectiveActionForm
  include ActiveModel::Model
  include ActiveModel::Attributes
  include ActiveModel::Serialization
  include ActiveModel::Validations::Callbacks
  include SanitizationHelper

  attribute :date_decided, :govuk_date
  attribute :product_id
  attribute :business_id
  attribute :legislation
  attribute :action
  attribute :details
  attribute :related_file
  attribute :measure_type
  attribute :duration
  attribute :geographic_scope
  attribute :other_action
  attribute :has_online_recall_information, :boolean, default: nil
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

  def load_document_file
    if existing_document_file_id.present? && document.nil?
      self.document = ActiveStorage::Blob.find_signed(existing_document_file_id)
      self.filename = document.filename.to_s
      self.file_description = document.metadata["description"]
    end
  end

  def file=(document_params)
    return unless related_file

    if document_params.key?(:file)
      file = document_params[:file]
      self.filename = file.original_filename
      self.file_description = document_params[:description]
      self.document = ActiveStorage::Blob.create_after_upload!(
        io: file,
        filename: file.original_filename,
        content_type: file.content_type,
        metadata: { description: file_description }
      )

      self.existing_document_file_id = document.signed_id
    else
      load_document_file
      return if document.nil?

      self.file_description = document_params.dig(:description)
      document.metadata[:description] = file_description
      document.save!
      document.reload
    end
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
end
