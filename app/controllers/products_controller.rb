class ProductsController < ApplicationController
  include CountriesHelper
  include ProductsHelper
  include UrlHelper
  helper_method :sort_column, :sort_direction

  before_action :set_search_params, only: %i[index]
  before_action :set_product, only: %i[show edit update]
  before_action :set_countries, only: %i[update edit]
  before_action :build_breadcrumbs, only: %i[show]

  # GET /products
  # GET /products.json
  def index
    @products = search_for_products(20)
  end

  # GET /products/1
  # GET /products/1.json
  def show
    respond_to do |format|
      format.html
    end
  end

  # GET /products/1/edit
  def edit
    @product_form = ProductForm.from(Product.find(params[:id]))
  end

  # PATCH/PUT /products/1
  # PATCH/PUT /products/1.json
  def update
    respond_to do |format|
      product = Product.find(params[:id])
      @product_form = ProductForm.from(product)
      @product_form.attributes = product_params

      if @product_form.valid?
        format.html do
          product.update!(attributes_to_update)
          redirect_to product_path(product), flash: { success: "Product was successfully updated." }
        end
        format.json { render :show, status: :ok, location: product }
      else
        format.html { render :edit }
        format.json { render json: product.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /products/1
  # DELETE /products/1.json
  def destroy
    @product.destroy!
    respond_to do |format|
      format.html { redirect_to products_path, flash: { success: "Product was successfully deleted." } }
      format.json { head :no_content }
    end
  end

private

  def build_breadcrumbs
    @breadcrumbs = build_back_link_to_case || build_breadcrumb_structure
  end

  def attributes_to_update
    number_of_affected_units = product_params['exact_units'] if product_params['affected_units_status'] == 'exact'
    number_of_affected_units = product_params['approx_units'] if product_params['affected_units_status'] == 'approx'

    {
      authenticity: @product_form.authenticity,
      batch_number: @product_form.batch_number,
      brand: @product_form.brand,
      country_of_origin: @product_form.country_of_origin,
      description: @product_form.description,
      gtin13: @product_form.gtin13,
      name: @product_form.name,
      product_code: @product_form.product_code,
      subcategory: @product_form.subcategory,
      category: @product_form.category,
      webpage: @product_form.webpage,
      affected_units_status: @product_form.affected_units_status,
      number_of_affected_units: number_of_affected_units
    }
  end
end
