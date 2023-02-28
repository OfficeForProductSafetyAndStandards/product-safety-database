class DocumentUpload < ApplicationRecord
  include SanitizationHelper

  belongs_to :upload_model, polymorphic: true

  has_one_attached :file_upload

  attribute :existing_file_upload_file_id, :string

  validates :file_upload, attached: true, size: { less_than: 100.megabytes, message: "must be smaller than 100MB" }
  validates :file_upload, attached: true, size: { greater_than: 1.bytes, message: "must be larger than 0MB" }
  validates :title, presence: true
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

    errors.add(:base, :virus, message: "File upload must be virus free")
  end
end
