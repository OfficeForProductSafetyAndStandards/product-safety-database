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
    respond_to do |format|
      format.html do
        results = search_for_products(20)
        @products = ProductDecorator.decorate_collection(results)
      end
      format.csv do
        authorize Product, :export?

        results = search_for_products.includes(:investigations)
        @products = ProductDecorator.decorate_collection(results)

        render csv: @products, filename: "products"
      end
    end
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
          product.update!(@product_form.serializable_hash)
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
end
