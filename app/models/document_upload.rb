class DocumentUpload < ApplicationRecord
  include SanitizationHelper

  belongs_to :upload_model, polymorphic: true

  has_one_attached :file_upload

  store_accessor :metadata, :title
  store_accessor :metadata, :description
  store_accessor :metadata, :created_by

  attribute :existing_file_upload_file_id, :string

  validates :file_upload, attached: true, size: { less_than: 100.megabytes, message: "must be smaller than 100MB" }
  validates :title, presence: true
  validates :description, length: { maximum: 10_000 }

  before_validation do
    trim_line_endings(:description)
  end
end
