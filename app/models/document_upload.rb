class DocumentUpload < ApplicationRecord
  include SanitizationHelper

  belongs_to :upload_model, polymorphic: true

  has_one_attached :file_upload

  attribute :existing_file_upload_file_id, :string

  validates :file_upload, attached: { message: "Select a file" }
  validates :file_upload, size: { less_than: 100.megabytes, message: "File must be smaller than 100MB" }, if: -> { file_upload.attached? }
  validates :file_upload, size: { greater_than: 1.byte, message: "File must be larger than 0MB" }, if: -> { file_upload.attached? }
  validates :title, presence: { message: "Enter a document title" }
  validates :description, length: { maximum: 10_000 }
  validate :file_is_free_of_viruses

  before_validation do
    trim_line_endings(:description)
  end

private

  def file_is_free_of_viruses
    # Don't run this validation unless document has been analyzed by antivirus analyzer
    return unless file_upload.metadata&.key?("safe")

    return if file_upload.metadata["safe"] == true

    errors.add(:file_upload, :virus, message: "File upload must be virus free")
  end
end
