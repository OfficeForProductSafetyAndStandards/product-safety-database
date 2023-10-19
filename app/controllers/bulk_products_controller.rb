class BulkProductsController < ApplicationController
  include CountriesHelper
  include UrlHelper
  include BreadcrumbHelper

  before_action :authorize_user

  breadcrumb "products.label", :products_path

  def triage
    if request.put?
      @bulk_products_triage_form = BulkProductsTriageForm.new(bulk_products_triage_params)

      if @bulk_products_triage_form.valid?
        case @bulk_products_triage_form.compliance_and_safety
        when "unsafe"
          redirect_to no_upload_unsafe_bulk_upload_products_path
        when "mixed"
          redirect_to no_upload_mixed_bulk_upload_products_path
        when "non_compliant"
          redirect_to create_case_bulk_upload_products_path
        end
      end
    else
      @bulk_products_triage_form = BulkProductsTriageForm.new
    end
  end

  def no_upload_unsafe; end

  def no_upload_mixed; end

  def create_case; end

private

  def authorize_user
    redirect_to "/403" if current_user && !current_user.can_bulk_upload_products?
  end

  def bulk_products_triage_params
    params.require(:bulk_products_triage_form).permit(:compliance_and_safety, :hazard_description)
  end
end
