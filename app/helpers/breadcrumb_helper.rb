module BreadcrumbHelper
  def display_breadcrumbs?
    request.path != authenticated_root_path
  end
end
