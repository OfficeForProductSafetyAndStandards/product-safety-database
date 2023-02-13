class DocumentUpload < ApplicationRecord

  belongs_to :upload_model, polymorphic: true

  # has_one_attached :file_upload ANTI-VIRUS META DATA
  has_one_attached :file_upload

  # title / description
  has_paper_trail
end
