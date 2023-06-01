module Products
  class DuplicateChecksController < ApplicationController
    before_action :find_product, only: %i[show confirm]

    def new
      @product_duplicate_check_form = ProductDuplicateCheckForm.new
    end

    def show
      @product_duplicate_confirmation_form = ProductDuplicateConfirmationForm.new
      @image = @product.virus_free_images.first&.decorate
    end

    def create
      @product_duplicate_check_form = ProductDuplicateCheckForm.new(product_duplicate_check_form_params)
      return render :new unless @product_duplicate_check_form.valid?

      @product_duplicates = FindClosestProductDuplicate.call(barcode: @product_duplicate_check_form.barcode)
      if @product_duplicates.duplicate&.present?
        first_duplicate_product = @product_duplicates.duplicate
        return redirect_to product_duplicate_checks_path(first_duplicate_product)
      end

      if @product_duplicate_check_form.has_barcode
        redirect_to new_product_path(barcode: @product_duplicate_check_form.barcode)
      else
        redirect_to new_product_path
      end
    end

    def confirm
      @product_duplicate_confirmation_form = ProductDuplicateConfirmationForm.new(correct: product_duplicate_confirmation_form_params[:correct])
      return render :show unless @product_duplicate_confirmation_form.valid?

      if @product_duplicate_confirmation_form.correct?
        redirect_to product_path(@product)
      else
        redirect_to new_product_path(barcode: @product.barcode)
      end
    end

  private

    def find_product
      @product = Product.find(params[:product_id]).decorate
    end

    def product_duplicate_check_form_params
      params.require(:product_duplicate_check_form)
            .permit(:has_barcode, :barcode)
    end

    def product_duplicate_confirmation_form_params
      params.require(:product_duplicate_confirmation_form)
            .permit(:correct)
    end
  end
end
