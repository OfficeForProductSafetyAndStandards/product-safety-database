module DocumentsHelper
  include FileConcern

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

  def pretty_type_description(document)
    description = ""
    description += document_file_extension(document) + " " if document_file_extension document
    description + image_document_text(document)
  end

  def formatted_file_updated_date(file)
    if file.blob.metadata[:updated]
      "Updated #{Time.zone.parse(file.blob.metadata[:updated]).to_s(:govuk)}"
    end
  end
end
