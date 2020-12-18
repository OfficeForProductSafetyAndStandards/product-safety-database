class TestResultForm
  include ActiveModel::Model
  include ActiveModel::Attributes
  include ActiveModel::Serialization
  include ActiveModel::Validations::Callbacks
  include ActiveModel::Dirty
  include SanitizationHelper

  attribute :id, :integer
  attribute :date, :govuk_date
  attribute :details
  attribute :legislation
  attribute :result
  attribute :standards_product_was_tested_against, :comma_separated_list
  attribute :product_id, :integer
  attribute :document
  attribute :existing_document_file_id
  attribute :filename
  attribute :file_description

  validates :details, length: { maximum: 50_000 }
  validates :legislation, inclusion: { in: Rails.application.config.legislation_constants["legislation"] }
  validates :standards_product_was_tested_against, presence: true
  validates :result, inclusion: { in: Test::Result.results.keys }
  validates :document, presence: true
  validates :product_id, presence: true, on: :create_with_product
  validates :date,
            presence: true,
            real_date: true,
            complete_date: true,
            not_in_future: true

  before_validation { trim_line_endings(:details, :file_description) }

  ATTRIBUTES_FROM_TEST_RESULT = %i[
    id date details legislation result standards_product_was_tested_against product_id
  ].freeze

  def self.from(test_result)
    new(test_result.serializable_hash(only: ATTRIBUTES_FROM_TEST_RESULT)).tap do |test_result_form|
      test_result_form.existing_document_file_id = test_result.document.signed_id
      test_result_form.load_document_file
      test_result_form.changes_applied
    end
  end

  def load_document_file
    if existing_document_file_id.present? && document.nil?
      self.document = ActiveStorage::Blob.find_signed(existing_document_file_id)
      self.filename = document.filename.to_s
      self.file_description = document.metadata["description"]
    end
  end

  def document_form=(document_params)
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
end
