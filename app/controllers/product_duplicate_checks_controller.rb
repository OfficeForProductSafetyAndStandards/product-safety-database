class ProductDuplicateChecksController < ApplicationController
  before_action :find_product, only: [:show]

  def new
    @product_duplicate_check_form = ProductDuplicateCheckForm.new
  end

  def show
  end

  def create
    @product_duplicate_check_form = ProductDuplicateCheckForm.new(product_duplicate_check_form_params)

    if @product_duplicate_check_form.valid?
      # TODO: if we find a duplicate, we should ask if they want to use the existing product
      if @product_duplicate_check_form.has_barcode
        # TODO: get product form to prefill barcode here
        redirect_to new_product_path(barcode: @product_duplicate_check_form.barcode)
      else
        # TODO: do we need a flash message here?
        redirect_to new_product_path
      end
    else
      render :new
    end
  end

private

  def find_product
    @product = Product.find_by!(pretty_id: params[:id])
  end

  def product_duplicate_check_form_params
    params.require(:product_duplicate_check_form)
          .permit(:has_barcode, :barcode)
  end
end
