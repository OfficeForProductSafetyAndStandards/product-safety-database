class ImageUpload < ApplicationRecord
  include SanitizationHelper

  belongs_to :upload_model, polymorphic: true

  has_one_attached :file_upload

  attribute :existing_file_upload_file_id, :string

  validates :file_upload, attached: true
  validates :file_upload, size: { less_than: 100.megabytes, message: "Image must be smaller than 100MB" }
  validates :file_upload, size: { greater_than: 1.byte, message: "Image must be larger than 0MB" }
  # Allow standard GIF/JPEG/PNG files as well as WEBP (if downloaded from the web) or HEIC/HEIF (if taken by a smartphone)
  validates :file_upload, content_type: { in: ["image/gif", "image/jpeg", "image/png", "image/heic", "image/heif", "image/webp"], message: "Image must be a GIF, JPEG, PNG, WEBP or HEIC/HEIF file" }
  validate :file_is_free_of_viruses

private

  def file_is_free_of_viruses
    # Don't run this validation unless document has been analyzed by antivirus analyzer
    return unless file_upload&.metadata&.key?("safe")

    return if file_upload&.metadata&.dig("safe") == true

    errors.add(:base, :virus, message: "File upload must be virus free")
  end
end
