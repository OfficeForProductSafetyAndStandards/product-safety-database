class BulkProductsController < ApplicationController
  include CountriesHelper
  include BreadcrumbHelper

  before_action :authorize_user
  before_action :bulk_products_upload, except: %i[triage no_upload_unsafe no_upload_mixed]
  before_action :set_countries, only: %i[add_business_details]

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
        @bulk_products_upload.investigation.update!(
          user_title: bulk_products_create_case_params[:name],
          complainant_reference: bulk_products_create_case_params[:reference_number_provided] == "true" ? bulk_products_create_case_params[:reference_number] : nil
        )

        redirect_to create_business_bulk_upload_products_path(@bulk_products_upload)
      end
    else
      @bulk_products_create_case_form = BulkProductsCreateCaseForm.from(@bulk_products_upload)
    end
  end

  def create_business
    @online_marketplaces = OnlineMarketplace.approved.order(:name)

    if request.put?
      @bulk_products_add_business_type_form = BulkProductsAddBusinessTypeForm.new(bulk_products_add_business_type_params)

      if @bulk_products_add_business_type_form.valid?
        ActiveRecord::Base.transaction do
          if @bulk_products_upload.investigation_business.present?
            online_marketplace = if bulk_products_add_business_type_params[:other_marketplace_name].present?
                                   OnlineMarketplace.find_or_create_by!(name: bulk_products_add_business_type_params[:other_marketplace_name], approved_by_opss: false)
                                 else
                                   OnlineMarketplace.find(bulk_products_add_business_type_params[:online_marketplace_id])
                                 end
            @bulk_products_upload.investigation_business.update!(
              relationship: bulk_products_add_business_type_params[:type],
              online_marketplace:,
              authorised_representative_choice: bulk_products_add_business_type_params[:authorised_representative_choice]
            )
          else
            # Use a fake name for now
            business = Business.create!(
              trading_name: "Auto-generated business for case #{@bulk_products_upload.investigation.pretty_id}",
              added_by_user: current_user
            )
            # Location will not be valid until a country is added at the next step
            business.locations.build(name: "Registered office address", added_by_user: current_user).save!(validate: false)
            business.contacts.create!
            AddBusinessToCase.call!(
              business:,
              relationship: bulk_products_add_business_type_params[:type],
              online_marketplace: bulk_products_add_business_type_params[:online_marketplace_id].present? ? OnlineMarketplace.find(bulk_products_add_business_type_params[:online_marketplace_id]) : nil,
              other_marketplace_name: bulk_products_add_business_type_params[:other_marketplace_name],
              authorised_representative_choice: bulk_products_add_business_type_params[:authorised_representative_choice],
              investigation: @bulk_products_upload.investigation,
              user: current_user
            )
            @bulk_products_upload.update!(investigation_business_id: business.reload.investigation_businesses.first.id)
          end
        end

        redirect_to add_business_details_bulk_upload_products_path(@bulk_products_upload)
      end
    else
      @bulk_products_add_business_type_form = BulkProductsAddBusinessTypeForm.from(@bulk_products_upload)
    end
  end

  def add_business_details
    if request.put?
      @bulk_products_add_business_details_form = BulkProductsAddBusinessDetailsForm.new(bulk_products_add_business_details_params)

      if @bulk_products_add_business_details_form.valid?
        @bulk_products_upload.investigation_business.business.update!(bulk_products_add_business_details_params)

        redirect_to upload_products_file_bulk_upload_products_path(@bulk_products_upload)
      end
    else
      @bulk_products_add_business_details_form = BulkProductsAddBusinessDetailsForm.from(@bulk_products_upload)
    end
  end

  def upload_products_file
    if request.put?
      @bulk_products_upload_products_file_form = BulkProductsUploadProductsFileForm.new(bulk_products_upload_products_file_params)
      @bulk_products_upload_products_file_form.cache_file!
      @bulk_products_upload_products_file_form.load_products_file

      if @bulk_products_upload_products_file_form.valid?
        @bulk_products_upload.update!(products_cache: @bulk_products_upload_products_file_form.products)

        redirect_to resolve_duplicate_products_bulk_upload_products_path(@bulk_products_upload)
      else
        @bulk_products_upload.update!(products_cache: [])
      end
    else
      @bulk_products_upload_products_file_form = BulkProductsUploadProductsFileForm.from(@bulk_products_upload)
      @bulk_products_upload_products_file_form.cache_file!
      @bulk_products_upload_products_file_form.load_products_file
    end
  end

  def resolve_duplicate_products; end

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

  def bulk_products_add_business_type_params
    params.require(:bulk_products_add_business_type_form).permit(:type, :online_marketplace_id, :other_marketplace_name, :authorised_representative_choice)
  end

  def bulk_products_add_business_details_params
    params.require(:bulk_products_add_business_details_form).permit(
      :trading_name, :legal_name, :company_number,
      locations_attributes: %i[id address_line_1 address_line_2 city county postal_code country],
      contacts_attributes: %i[id name email phone_number job_title]
    )
  end

  def bulk_products_upload_products_file_params
    # `random_uuid` allows us to detect a missing file upload
    params.require(:bulk_products_upload_products_file_form).permit(:random_uuid, :products_file)
  end
end
