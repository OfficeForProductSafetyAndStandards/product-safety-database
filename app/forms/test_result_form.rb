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

  define_attribute_methods :date, :govuk_date
  define_attribute_methods :details
  define_attribute_methods :legislation
  define_attribute_methods :result
  define_attribute_methods :standards_product_was_tested_against
  define_attribute_methods :product_id

  validates :details, length: { maximum: 50_000 }
  validates :legislation, inclusion: { in: Rails.application.config.legislation_constants["legislation"] }
  validates :result, inclusion: { in: Test::Result.results.keys }
  validates :document, presence: true
  validates :product_id, presence: true, on: :create_with_product
  validates :date,
            presence: true,
            real_date: true,
            complete_date: true,
            not_in_future: true

  before_validation { trim_line_endings(:details) }

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
    end
  end

  def document_form=(document_params)
    if document_params.key?(:file)
      file = document_params[:file]
      self.document = ActiveStorage::Blob.create_after_upload!(
        io: file,
        filename: file.original_filename,
        content_type: file.content_type,
        metadata: { description: document_params[:description] }
      )

      self.existing_document_file_id = document.signed_id
    else
      document.metadata[:description] = document_params[:description]
      document.save!
    end
  end
end
