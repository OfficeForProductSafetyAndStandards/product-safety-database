class BulkProductsController < ApplicationController
  include CountriesHelper

  before_action :authorize_user
  before_action :bulk_products_upload, except: %i[triage no_upload_unsafe no_upload_mixed]
  before_action :set_countries, only: %i[add_business_details]
  skip_before_action :set_home_breadcrumb

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
          context = CreateBulkProductsUpload.call!(hazard_description: bulk_products_triage_params[:hazard_description], user: current_user)
          @bulk_products_upload = context.bulk_products_upload

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
        UpdateBulkProductsUploadCase.call!(
          bulk_products_upload: @bulk_products_upload,
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
        if @bulk_products_upload.investigation_business.present?
          UpdateBulkProductsUploadBusiness.call!(
            bulk_products_upload: @bulk_products_upload,
            type: bulk_products_add_business_type_params[:type],
            online_marketplace_id: bulk_products_add_business_type_params[:online_marketplace_id],
            other_marketplace_name: bulk_products_add_business_type_params[:other_marketplace_name],
            authorised_representative_choice: bulk_products_add_business_type_params[:authorised_representative_choice],
            user: current_user
          )
        else
          CreateBulkProductsUploadBusiness.call!(
            bulk_products_upload: @bulk_products_upload,
            type: bulk_products_add_business_type_params[:type],
            online_marketplace_id: bulk_products_add_business_type_params[:online_marketplace_id],
            other_marketplace_name: bulk_products_add_business_type_params[:other_marketplace_name],
            authorised_representative_choice: bulk_products_add_business_type_params[:authorised_representative_choice],
            user: current_user
          )
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

  def resolve_duplicate_products
    # If there is nothing in the cache then we don't have a valid file, so redirect to the file upload page
    return redirect_to upload_products_file_bulk_upload_products_path(@bulk_products_upload) if @bulk_products_upload.products_cache.empty?

    # Barcodes from all uploaded products
    barcodes = @bulk_products_upload.products_cache.pluck("barcode").compact

    # Gets the newest product per barcode to present to the user as an alternative to what they've submitted
    @duplicate_products = Product.where(barcode: barcodes).select("DISTINCT ON (products.barcode) barcode, products.*").order(barcode: :asc, updated_at: :desc)

    # If there are no duplicates then we can progress to the next page
    return redirect_to review_products_bulk_upload_products_path(@bulk_products_upload, barcodes:) if @duplicate_products.empty?

    # Used by the form to validate that all duplicate products have a resolution
    duplicate_barcodes = @duplicate_products.map(&:barcode)

    if request.put?
      @bulk_products_resolve_duplicate_products_form = BulkProductsResolveDuplicateProductsForm.new(bulk_products_resolve_duplicate_products_params.merge(duplicate_barcodes:))

      if @bulk_products_resolve_duplicate_products_form.valid?
        # Get IDs for all products where the user has chosen to use an existing product
        product_ids_to_use = @bulk_products_resolve_duplicate_products_form.resolution.filter_map { |_barcode, resolution| resolution.split(";").last if resolution.start_with?("existing_record") }

        # Get all barcodes where the user has either chosen to use their uploaded product or the product was not a duplicate
        barcodes_to_create = barcodes - duplicate_barcodes + @bulk_products_resolve_duplicate_products_form.resolution.filter_map { |barcode, resolution| barcode if resolution == "new_record" }

        redirect_to review_products_bulk_upload_products_path(
          @bulk_products_upload,
          product_ids: product_ids_to_use,
          barcodes: barcodes_to_create
        )
      end
    else
      @bulk_products_resolve_duplicate_products_form = BulkProductsResolveDuplicateProductsForm.new(duplicate_barcodes:)
    end
  end

  def review_products
    # If there is nothing in the cache then we don't have a valid file, so redirect to the file upload page
    # Also redirect if there are no barcodes or product IDs to review
    return redirect_to upload_products_file_bulk_upload_products_path(@bulk_products_upload) if @bulk_products_upload.products_cache.empty? || (params[:barcodes].blank? && params[:product_ids].blank?)

    new_products = if params[:barcodes].present?
                     @bulk_products_upload.products_cache.filter_map do |product|
                       { product: Product.new(product["product_data"].except("image", "existing_image_file_id")), investigation_product: InvestigationProduct.new(product["investigation_data"]) } if params[:barcodes].include?(product["barcode"])
                     end
                   else
                     []
                   end
    existing_products = Product.where(id: params[:product_ids]).map do |product|
      { product:, investigation_product: product.investigation_products&.first }
    end
    @products_to_review = new_products + existing_products

    if request.put?
      @bulk_products_review_products_form = BulkProductsReviewProductsForm.new(bulk_products_review_products_params)

      if @bulk_products_review_products_form.valid?
        CreateBulkProductsUploadProducts.call!(
          bulk_products_upload: @bulk_products_upload,
          new_products:,
          existing_products:,
          images: @bulk_products_review_products_form.images,
          user: current_user
        )

        redirect_to choose_products_for_corrective_actions_bulk_upload_products_path(@bulk_products_upload)
      end
    else
      @bulk_products_review_products_form = BulkProductsReviewProductsForm.new
    end
  end

  def cancel_and_reupload
    @bulk_products_upload.update!(products_cache: [])
    redirect_to upload_products_file_bulk_upload_products_path(@bulk_products_upload)
  end

  def choose_products_for_corrective_actions; end

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

  def bulk_products_resolve_duplicate_products_params
    # `random_uuid` allows us to detect a missing file upload
    params.require(:bulk_products_resolve_duplicate_products_form).permit(:random_uuid, resolution: {})
  end

  def bulk_products_review_products_params
    # `random_uuid` allows us to continue even if no images are uploaded
    params.require(:bulk_products_review_products_form).permit(:random_uuid, images: {})
  end
end
