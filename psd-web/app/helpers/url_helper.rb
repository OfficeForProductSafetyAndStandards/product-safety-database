module UrlHelper
  # Due to STI on the Investigation subclasses and renaming of the named routes
  # polymorphic_path resolves to the wrong controller when given an instance of
  # an Investigation subclass. This is a sticky plaster on a crazy design.
  #
  def path_for_model(object, *slug)
    slug = Array(slug)

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

  def attachments_tab_path(parent, file)
    if parent.is_a?(Investigation)
      path_for_model(parent) + (file.image? ? "/images" : "/supporting-information")
    else
      path_for_model(parent) + "#attachments"
    end
  end

  # DOCUMENTS
  def associated_documents_path(parent)
    path_for_model(parent, :documents)
  end

  def associated_document_path(parent, document)
    path_for_model(parent, :documents) + "/" + document.id.to_s
  end

  def new_associated_document_path(parent)
    path_for_model(parent, :documents) + "/new"
  end

  def new_document_flow_path(parent)
    path_for_model(parent, :documents) + "/new/new"
  end

  def edit_associated_document_path(parent, document)
    associated_document_path(parent, document) + "/edit"
  end

  def remove_associated_document_path(parent, document)
    associated_document_path(parent, document) + "/remove"
  end

  def build_back_link_to_case
    case_id = request.referer&.match(/cases\/(\d+-\d+)/)&.captures&.first
    return nil if case_id.blank?

    investigation = Investigation.find_by!(pretty_id: case_id).decorate
    {
      is_simple_link: true,
      text: "Back to #{investigation.pretty_description}",
      href: investigation_path(investigation)
    }
  end
end
