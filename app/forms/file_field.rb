class FileField
  include ActiveModel::Model
  include ActiveModel::Attributes
  include SanitizationHelper

  attribute :description
  attribute :file

  delegate :original_filename, :content_type, to: :file

  def initialize(*args)
    super
    trim_line_endings(:description)
  end
end
