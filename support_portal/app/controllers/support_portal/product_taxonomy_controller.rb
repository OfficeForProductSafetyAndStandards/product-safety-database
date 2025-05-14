module SupportPortal
  class ProductTaxonomyController < ApplicationController
    before_action :check_current_user_authorised

    # GET /
    def index
      imports = ::ProductTaxonomyImport.includes(:user).all.order(created_at: :desc)
      @records_count = imports.size
      @pagy, @records = pagy(imports)
    end

    # GET /taxonomy
    def taxonomy
      taxonomy = ::ProductCategory.includes(:product_subcategories).all.order(:name)
      @records_count = taxonomy.size
      @pagy, @records = pagy(taxonomy)
    end

    # GET /new
    def new
      @product_taxonomy_import = ::ProductTaxonomyImport.new
    end

    # POST /new
    def create
      @product_taxonomy_import = ::ProductTaxonomyImport.new(product_taxonomy_import_params.merge(user: current_user))

      if @product_taxonomy_import.valid?
        file = ActiveStorage::Blob.create_and_upload!(
          io: product_taxonomy_import_params[:import_file],
          filename: product_taxonomy_import_params[:import_file].original_filename,
          content_type: product_taxonomy_import_params[:import_file].content_type
        )
        file.analyze_later
        @product_taxonomy_import.import_file = file
      else
        return render :new
      end

      if @product_taxonomy_import.valid?(:validate_format)
        @product_taxonomy_import.save!
      else
        return render :new
      end

      # Reload the uploaded file to get the latest metadata for virus status
      @product_taxonomy_import.import_file.try(:reload)

      if @product_taxonomy_import.import_file.virus?
        flash[:warning] = "The product taxonomy file is infected with a virus and will be deleted - please upload again"
        return render :new
      end

      @product_taxonomy_import.mark_as_file_uploaded!
      ProductTaxonomyImportJob.perform_later(@product_taxonomy_import.id)
      redirect_to product_taxonomy_index_path, notice: "Product taxonomy file uploaded - refresh to check progress"
    end

  private

    def check_current_user_authorised
      redirect_to "/" unless current_user.has_role?("update_product_taxonomy")
    end

    def product_taxonomy_import_params
      params.require(:product_taxonomy_import).permit(:import_file, :_dummy)
    end
  end
end
