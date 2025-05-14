class DocumentUpload < ApplicationRecord
  include SanitizationHelper

  belongs_to :upload_model, polymorphic: true

  has_one_attached :file_upload

  attribute :existing_file_upload_file_id, :string

  validates :file_upload, attached: true, size: { less_than: 100.megabytes, message: "File must be smaller than 100MB" }
  validates :file_upload, attached: true, size: { greater_than: 1.byte, message: "File must be larger than 0MB" }
  validates :title, presence: true
  validates :description, length: { maximum: 10_000 }

  before_validation do
    trim_line_endings(:description)
  end
end
