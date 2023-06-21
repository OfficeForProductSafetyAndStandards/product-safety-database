module BreadcrumbHelper
  def display_breadcrumbs?
    devise_controllers = ["users/sessions", "users/unlocks", "users/passwords", "users/check_your_email"]
    return false if devise_controllers.include?(params[:controller])

    request.path != authenticated_root_path
  end

  def breadcrumb_case_label
    setting = cookies.fetch(:last_case_view, "your_cases")
    setting = "all_cases" if setting == "index"
    "cases.#{setting}".to_sym
  end

  def breadcrumb_case_path
    setting = cookies.fetch(:last_case_view, "your_cases")
    setting = "all_cases" if setting == "index"
    "#{setting}_investigations".to_sym
  end

  def breadcrumb_business_label
    setting = cookies.fetch(:last_business_view, "your_businesses")
    setting = "all_businesses" if setting == "index"
    "businesses.#{setting}".to_sym
  end

  def breadcrumb_business_path
    setting = cookies.fetch(:last_business_view, "your_businesses")
    setting = "all_businesses" if setting == "index"
    setting.to_s.to_sym
  end

  def breadcrumb_product_label
    setting = cookies.fetch(:last_product_view, "your_products")
    setting = "all_products" if setting == "index"
    "products.#{setting}".to_sym
  end

  def breadcrumb_product_path
    setting = cookies.fetch(:last_product_view, "your_products")
    setting = "all_products" if setting == "index"
    setting.to_s.to_sym
  end
end
