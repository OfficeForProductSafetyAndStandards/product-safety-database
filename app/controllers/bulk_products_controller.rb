class BulkProductsController < ApplicationController
  include CountriesHelper
  include UrlHelper
  include BreadcrumbHelper

  before_action :authorize_user
  before_action :bulk_products_upload, except: %i[triage no_upload_unsafe no_upload_mixed]

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
          ActiveRecord::Base.transaction do
            investigation = Investigation::Notification.new(reported_reason: "non_compliant", hazard_description: bulk_products_triage_params[:hazard_description])
            CreateCase.call!(investigation:, user: current_user, bulk: true)
            @bulk_products_upload = BulkProductsUpload.create!(investigation:, user: current_user)
          end

          redirect_to create_case_bulk_upload_products_path(@bulk_products_upload)
        end
      end
    else
      @bulk_products_triage_form = BulkProductsTriageForm.new
    end
  end

  def no_upload_unsafe; end

  def no_upload_mixed; end

  def create_case
    if request.put?
      @bulk_products_create_case_form = BulkProductsCreateCaseForm.new(bulk_products_create_case_params)

      if @bulk_products_create_case_form.valid?
        @bulk_products_upload.investigation.update!(user_title: bulk_products_create_case_params[:name], complainant_reference: bulk_products_create_case_params[:reference_number])

        redirect_to create_business_bulk_upload_products_path(@bulk_products_upload)
      end
    else
      @bulk_products_create_case_form = BulkProductsCreateCaseForm.from(@bulk_products_upload)
    end
  end

  def create_business; end

private

  def authorize_user
    redirect_to "/403" if current_user && !current_user.can_bulk_upload_products?
  end

  def bulk_products_upload
    @bulk_products_upload ||= BulkProductsUpload.where(id: params[:bulk_products_upload_id], user: current_user).first!
  end

  def bulk_products_triage_params
    params.require(:bulk_products_triage_form).permit(:compliance_and_safety, :hazard_description)
  end

  def bulk_products_create_case_params
    params.require(:bulk_products_create_case_form).permit(:name, :reference_number, :reference_number_provided)
  end
end
