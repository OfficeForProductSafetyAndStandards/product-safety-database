module BreadcrumbHelper
  def display_breadcrumbs?
    devise_controllers = ["users/sessions", "users/unlocks", "users/passwords", "users/check_your_email"]
    return false if devise_controllers.include?(params[:controller])

    request.path != authenticated_root_path
  end
end
