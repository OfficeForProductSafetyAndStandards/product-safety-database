class ImageUploadDecorator < ApplicationDecorator
  delegate_all

  def title
    object.file_upload.filename.to_s
  end

  def supporting_information_title
    object.file_upload.filename.to_s
  end

  def event_type
    File.extname(object.file_upload.filename.to_s)&.remove(".")&.upcase
  end

  def date_of_activity
    object.created_at.to_formatted_s(:govuk)
  end

  def date_added
    object.created_at.to_formatted_s(:govuk)
  end

  def updated_at
    object.updated_at.to_formatted_s(:govuk)
  end

  def show_path
    h.investigation_document_path(Investigation.find_by(id: object.id), object)
  end
end
