class TestResultForm
  include ActiveModel::Model
  include ActiveModel::Attributes
  include ActiveModel::Serialization
  include SanitizationHelper

  attribute :id
  attribute :date, :govuk_date
  attribute :details
  attribute :legislation
  attribute :result
  attribute :standards_product_was_tested_against, :comma_separated_list
  attribute :product_id
  attribute :document, :file_field
  attribute :existing_document_file_id

  validates :details, length: { maximum: 50_000 }
  validates :legislation, inclusion: { in: Rails.application.config.legislation_constants["legislation"] }
  validates :result, inclusion: { in: Test::Result.results.keys }
  validates :document, presence: true
  validates :date,
            presence: true,
            real_date: true,
            complete_date: true,
            not_in_future: true

  ATTRIBUTES_FROM_TEST_RESULT = %i[
    id date details legislation result standards_product_was_tested_against product_id
  ].freeze

  def self.from(test_result)
    new(test_result.serializable_hash(only: ATTRIBUTES_FROM_TEST_RESULT)).tap do |test_result_form|
      test_result_form.existing_document_file_id = test_result.document.signed_id
    end
  end

  def initialize(*args)
    super
    trim_line_endings(:details)
  end

  def cache_file!
    return if document.blank?

    self.document = ActiveStorage::Blob.create_after_upload!(
      io: document.file,
      filename: document.original_filename,
      content_type: document.content_type,
      metadata: { description: document.description }
    )

    self.existing_document_file_id = document.signed_id
  end

  def load_document_file
    if existing_document_file_id.present? && document.nil?
      self.document = ActiveStorage::Blob.find_signed(existing_document_file_id)
    end
  end
end
