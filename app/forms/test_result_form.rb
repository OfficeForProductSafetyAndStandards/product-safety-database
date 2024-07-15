class TestResultForm
  include ActiveModel::Model
  include ActiveModel::Attributes
  include ActiveModel::Serialization
  include ActiveModel::Validations::Callbacks
  include ActiveModel::Dirty
  include SanitizationHelper
  include HasDocumentAttachedConcern

  attribute :id, :integer
  attribute :date, :govuk_date
  attribute :details
  attribute :legislation
  attribute :result
  attribute :standards_product_was_tested_against, :comma_separated_list
  attribute :investigation_product_id, :integer
  attribute :document
  attribute :existing_document_file_id
  attribute :filename
  attribute :file_description
  attribute :failure_details
  attribute :further_test_results

  attribute :tso_certificate_reference_number, :string
  attribute :tso_certificate_issue_date, :govuk_date

  validates :details, length: { maximum: 32_767 }
  validates :legislation, inclusion: { in: Rails.application.config.legislation_constants["legislation"] }
  validates :standards_product_was_tested_against, presence: true
  validates :date,
            presence: true,
            real_date: true,
            complete_date: true,
            not_in_future: true,
            recent_date: { on_or_before: false }
  validates :result, inclusion: { in: Test::Result.results.keys }
  validates :document, presence: true
  validates :investigation_product_id, presence: true, on: :create_with_investigation_product
  validates :further_test_results, presence: true, on: :ts_user_create
  validates :failure_details, presence: true, if: -> { result == "failed" }

  before_validation do
    trim_line_endings(:details, :file_description)
    make_failure_details_nil_if_empty
  end

  ATTRIBUTES_FROM_TEST_RESULT = %i[
    id date details legislation result failure_details standards_product_was_tested_against investigation_product_id tso_certificate_reference_number tso_certificate_issue_date
  ].freeze

  def self.from(test_result)
    new(test_result.serializable_hash(only: ATTRIBUTES_FROM_TEST_RESULT)).tap do |test_result_form|
      test_result_form.existing_document_file_id = test_result.document.signed_id
      test_result_form.load_document_file
      test_result_form.changes_applied
    end
  end

  def cache_file!(user)
    if document.is_a?(ActiveStorage::Blob)
      document.metadata["title"] = title
      document.metadata["description"] = description
      document.metadata["updated"] = Time.zone.now
      document.save!
    elsif document.instance_of?(String)
      self.document = ActiveStorage::Blob.find(document)
      document.update!(metadata: { updated: Time.zone.now })
    elsif document
      self.document = ActiveStorage::Blob.create_and_upload!(
        io: document,
        filename: document.original_filename,
        content_type: document.content_type
      )
      document.update!(metadata: { title: document.filename, description: "", created_by: user.id, updated: Time.zone.now })
      document.analyze_later
    end
  end

  def document_form=(document_params)
    assign_file_and_description(document_params)
  end

  def make_failure_details_nil_if_empty
    self.failure_details = nil if failure_details.try(:empty?)
  end
end
