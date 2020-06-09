module DocumentsHelper
  include FileConcern

  def document_placeholder(file_extension)
    render "documents/placeholder", file_extension: file_extension
  end

  def set_parent
    @parent = Investigation.find_by!(pretty_id: params[:investigation_pretty_id]) if params[:investigation_pretty_id]
    @parent ||= Investigation.find_by!(pretty_id: params[:allegation_id]) if params[:allegation_id]
    @parent ||= Investigation.find_by!(pretty_id: params[:project_id]) if params[:project_id]
    @parent ||= Investigation.find_by!(pretty_id: params[:inquiry]) if params[:inquiry]
    @parent ||= Product.find(params[:product_id]) if params[:product_id]
    @parent ||= Business.find(params[:business_id]) if params[:business_id]
  end

  def file_collection
    @parent.documents
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

  def formatted_file_updated_date(file)
    if file.blob.metadata[:updated]
      "Updated #{Time.zone.parse(file.blob.metadata[:updated]).to_s(:govuk)}"
    end
  end
end
