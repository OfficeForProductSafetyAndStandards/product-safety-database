module BreadcrumbHelper
  def display_breadcrumbs?
    devise_controllers = ["users/sessions", "users/unlocks", "users/passwords", "users/check_your_email"]
    other_controllers = ["introduction", "secondary_authentications", "secondary_authentications/resend_code"]

    return false if devise_controllers.include?(params[:controller]) || other_controllers.include?(params[:controller])

    request.path != authenticated_root_path
  end

  def breadcrumb_case_label
    setting = cookies.fetch(:last_case_view, "your_cases")
    setting = "all_cases" if setting == "index"
    "cases.#{setting}".to_sym
  end

  def breadcrumb_case_path
    setting = cookies.fetch(:last_case_view, "your_cases")

    return :notifications if setting == "index"

    setting = "all_cases"

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

  def breadcrumb_prism_risk_assessment_label
    setting = cookies.fetch(:last_prism_risk_assessment_view, "your_prism_risk_assessments")
    setting = "all_prism_risk_assessments" if setting == "index"
    "prism_risk_assessments.#{setting}".to_sym
  end

  def breadcrumb_prism_risk_assessment_path
    setting = cookies.fetch(:last_prism_risk_assessment_view, "your_prism_risk_assessments")
    setting = "all_prism_risk_assessments" if setting == "index"
    setting.to_s.to_sym
  end
end
