module DocumentUploadsHelper
  def document_upload_placeholder(document)
    render "document_uploads/placeholder", document:
  end

  def product_image_preview(image, dimensions)
    render "products/image_preview", image:, dimensions:
  end

  def document_upload_file_extension(document)
    File.extname(document.file_upload.filename.to_s)&.remove(".")&.upcase
  end

  def document_upload_path(document)
    return investigation_document_upload_path(document.upload_model, document) if document.upload_model.is_a?(Investigation)

    return product_document_upload_path(document.upload_model, document) if document.upload_model.is_a?(Product)

    return business_document_upload_path(document.upload_model, document) if document.upload_model.is_a?(Business)

    ""
  end

  def document_upload_filename_with_size(document)
    "#{document.file_upload.filename} (#{number_to_human_size(document.file_upload.blob.byte_size)})"
  end

  def document_upload_pretty_type_description(document)
    return "audio" if document.file_upload.audio?
    return "image" if document.file_upload.image?
    return "video" if document.file_upload.video?
    return "text document" if document.file_upload.text?

    case document.file_upload.content_type
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
      document_upload_file_extension(document).upcase
    end
  end

  def document_upload_spreadsheet?(document)
    spreadsheet_content_types = [
      "application/vnd.ms-excel",
      "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
    ]

    spreadsheet_content_types.include?(document.file_upload.content_type)
  end

  def formatted_document_upload_updated_date(document)
    "Updated #{document_upload_updated_date_in_govuk_format document}"
  end

  def document_upload_updated_date_in_govuk_format(document)
    document.updated_at.to_formatted_s(:govuk)
  end

  def documentable_policy(record)
    # NOTE: record will be the parent record, not the document!
    # NOTE: Pundit doesn't have a policy helper that allows the overriding
    #   of policy_class, so this helper manually instantiates an instance
    DocumentablePolicy.new current_user, record
  end
end
