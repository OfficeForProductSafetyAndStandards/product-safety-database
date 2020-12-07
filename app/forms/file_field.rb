class FileField
  include ActiveModel::Model
  include ActiveModel::Attributes
  include ActiveModel::Validations::Callbacks
  include ActiveModel::Dirty
  include SanitizationHelper

  attribute :description
  attribute :file

  before_validation { trim_line_endings(:description) }

  delegate :original_filename, :content_type, to: :file
end
