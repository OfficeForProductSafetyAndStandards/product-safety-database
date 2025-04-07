require "aasm"

class ProductTaxonomyImport < ApplicationRecord
  include AASM

  belongs_to :user
  # The XLSX file the user uploads that has a single worksheet with categories and matching sub-categories
  has_one_attached :import_file
  # The XLSX file that is generated, having one worksheet per category, each worksheet containing matching sub-categories
  has_one_attached :export_file
  # The XLSX file that is created from a template with the latest categories and sub-categories
  has_one_attached :bulk_upload_template_file

  # This is used on the upload page in case there are no other fields to make strong params work.
  attribute :_dummy, :string

  validates :import_file, attached: true, size: { less_than: 10.megabytes, message: "The selected file must be smaller than 10MB" }
  validates :import_file, attached: true, size: { greater_than: 1.byte, message: "The selected file must be larger than 0MB" }
  validate :file_is_free_of_viruses
  validate :file_is_an_excel_workbook
  validate :file_is_in_expected_format, on: :validate_format

  aasm column: :state, whiny_transitions: false do
    state :draft, initial: true
    state :file_uploaded
    state :database_updated
    state :export_file_created
    state :bulk_upload_template_created
    state :completed

    event :mark_as_file_uploaded do
      transitions from: :draft, to: :file_uploaded do
        guard do
          import_file.attached?
        end
      end
    end

    event :mark_as_database_updated do
      transitions from: :file_uploaded, to: :database_updated do
        guard do
          import_successful?
        end
      end
    end

    event :mark_as_export_file_created do
      transitions from: :database_updated, to: :export_file_created do
        guard do
          export_file.attached?
        end
      end
    end

    event :mark_as_bulk_upload_template_created do
      transitions from: :export_file_created, to: :bulk_upload_template_created do
        guard do
          bulk_upload_template_file.attached?
        end
      end
    end

    event :mark_as_completed do
      transitions from: :bulk_upload_template_created, to: :completed
    end
  end

  STATE_TO_STATUS_MAPPING = {
    "draft" => "Draft",
    "file_uploaded" => "File uploaded",
    "database_updated" => "Database updated",
    "export_file_created" => "Export file created",
    "bulk_upload_template_created" => "Bulk upload template created",
    "completed" => "Completed"
  }.freeze

  def status
    STATE_TO_STATUS_MAPPING[state]
  end

private

  def file_is_free_of_viruses
    # Don't run this validation unless document has been analyzed by antivirus analyzer
    return unless import_file&.metadata&.key?("safe")

    return if import_file&.metadata&.dig("safe") == true

    errors.add(:import_file, :virus, message: "The selected file must be virus free")
  end

  def file_is_an_excel_workbook
    return unless import_file.attached?

    return if import_file&.content_type == "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"

    errors.add(:import_file, :wrong_type, message: "The selected file must be an Excel file (XLSX)")
  end

  def file_is_in_expected_format
    return unless import_file.attached?

    import_file.open do |file|
      workbook = RubyXL::Parser.parse(file.path)

      # We're expecting one worksheet
      if workbook.worksheets.size != 1
        errors.add(:import_file, :too_many_worksheets, message: "The selected file has too many worksheets")
        break
      end

      # We're expecting two columns of data
      workbook.worksheets[0].sheet_data.rows.each_with_index do |row, index|
        next if index.zero? # ignore the heading row

        if row[0].value.blank? || row[1].value.blank?
          errors.add(:import_file, :missing_data, message: "The seleced file has incomplete data on row #{index + 1}")
        end

        if row[2].present?
          errors.add(:import_file, :extra_data, message: "The selected file has extra data on row #{index + 1}")
        end
      end
    end
  end

  def import_successful?
    ProductCategory.count.positive? && ProductCategory.first.created_at > created_at &&
      ProductSubcategory.count.positive? && ProductSubcategory.first.created_at > created_at
  end
end
