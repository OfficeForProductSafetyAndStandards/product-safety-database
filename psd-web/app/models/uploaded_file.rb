class UploadedFile
  include ActiveModel::Model
  include ActiveModel::Attributes

  attribute :description
  attribute :file
end
