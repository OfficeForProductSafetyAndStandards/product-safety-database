module UrlHelper
  # Due to STI on the Investigation subclasses and renaming of the named routes
  # polymorphic_path resolves to the wrong controller when given an instance of
  # an Investigation subclass. This is a sticky plaster on a crazy design.
  #
  def path_for_model(object, *slug)
    slug = Array(slug).compact.map(&:to_sym)

    if object.is_a?(Investigation)
      model = :investigation
      param_key = slug.any? ? :investigation_pretty_id : :pretty_id
      params = { param_key => object.pretty_id }
    else
      model = object
      params = {}
    end

    polymorphic_path([model] + slug, params)
  end

  def attachments_tab_path(parent, file = nil)
    if parent.is_a?(Investigation)
      path_for_model(parent) + (file.is_a?(ImageUpload) || file&.image? ? "/images" : "/supporting-information")
    else
      "#{path_for_model(parent)}#attachments"
    end
  end

  # DOCUMENTS
  def associated_documents_path(parent)
    path_for_model(parent, :documents)
  end

  def associated_document_path(parent, document)
    "#{path_for_model(parent, :documents)}/#{document.id}"
  end

  def edit_associated_document_path(parent, document)
    "#{associated_document_path(parent, document)}/edit"
  end

  def remove_associated_document_path(parent, document)
    "#{associated_document_path(parent, document)}/remove"
  end

  # DOCUMENT UPLOADS
  def associated_document_uploads_path(parent)
    path_for_model(parent, :document_uploads)
  end

  def associated_document_upload_path(parent, document_upload)
    "#{path_for_model(parent, :document_uploads)}/#{document_upload.id}"
  end

  def edit_associated_document_upload_path(parent, document_upload)
    "#{associated_document_upload_path(parent, document_upload)}/edit"
  end

  def remove_associated_document_upload_path(parent, document_upload)
    "#{associated_document_upload_path(parent, document_upload)}/remove"
  end

  # IMAGE UPLOADS
  def associated_image_uploads_path(parent)
    path_for_model(parent, :image_uploads)
  end

  def associated_image_upload_path(parent, image_upload)
    "#{path_for_model(parent, :image_uploads)}/#{image_upload.id}"
  end

  def remove_associated_image_upload_path(parent, image_upload)
    "#{associated_image_upload_path(parent, image_upload)}/remove"
  end
end
