class ProductDuplicateChecksController < ApplicationController
  before_action :find_product, only: [:show]

  def new
    @product_duplicate_check_form = ProductDuplicateCheckForm.new
  end

  def show
  end

  def create
    @product_duplicate_check_form = ProductDuplicateCheckForm.new(product_duplicate_check_form_params)
    return render :new unless @product_duplicate_check_form.valid?

    @product_duplicates = FindProductDuplicates.call(barcode: @product_duplicate_check_form.barcode)
    if @product_duplicates.duplicates.any?
      first_duplicate_product = @product_duplicates.duplicates.first
      return redirect_to product_duplicate_check_path(id: first_duplicate_product.id)
    end

    if @product_duplicate_check_form.has_barcode
      redirect_to new_product_path(barcode: @product_duplicate_check_form.barcode)
    else
      # TODO: do we need a flash message here?
      redirect_to new_product_path
    end
  end

private

  def find_product
    @product = Product.find(params[:id])
  end

  def product_duplicate_check_form_params
    params.require(:product_duplicate_check_form)
          .permit(:has_barcode, :barcode)
  end
end
