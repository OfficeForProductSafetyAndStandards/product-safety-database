module DocumentsHelper
  include FileConcern

  def document_placeholder(document)
    render "documents/placeholder", document:
  end

  def document_file_extension(document)
    File.extname(document.filename.to_s)&.remove(".")&.upcase
  end

  def filename_with_size(file)
    "#{file.filename} (#{number_to_human_size(file.blob.byte_size)})"
  end

  def pretty_type_description(document)
    return "audio" if document.audio?
    return "image" if document.image?
    return "video" if document.video?
    return "text document" if document.text?

    case document.content_type
    when "application/pdf"
      "PDF document"
    when "application/msword",
      "application/vnd.openxmlformats-officedocument.wordprocessingml.document"
      "Word document"
    when "application/vnd.ms-excel",
      "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
      "Excel document"
    when "application/vnd.ms-powerpoint",
      "application/vnd.openxmlformats-officedocument.presentationml.presentation"
      "PowerPoint document"
    else
      document_file_extension(document).upcase
    end
  end

  def spreadsheet?(document)
    spreadsheet_content_types = [
      "application/vnd.ms-excel",
      "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
    ]

    spreadsheet_content_types.include?(document.content_type)
  end

  def formatted_file_updated_date(file)
    if file.blob.metadata[:updated]
      "Updated #{file_updated_date_in_govuk_format file}"
    end
  end

  def file_updated_date_in_govuk_format(file)
    if file.blob.metadata[:updated]
      Time.zone.parse(file.blob.metadata[:updated]).to_formatted_s(:govuk)
    end
  end

  def documentable_policy(record)
    # NOTE: record will be the parent record, not the document!
    # NOTE: Pundit doesn't have a policy helper that allows the overriding
    #   of policy_class, so this helper manually instantiates an instance
    DocumentablePolicy.new current_user, record
  end
end
