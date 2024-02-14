class Api::V1::ProductsController < Api::BaseController
  include Pagy::Backend
  include ProductsHelper
  before_action :product, only: :show
  before_action :set_search_params, only: %i[index]

  def index
    @pagy, @results = search_for_products
    @count = count_to_display
    @products = ProductDecorator.decorate_collection(@results)
  end

  def create
    @product_form = ProductForm.new(product_create_params)

    if @product_form.valid?
      context = CreateProduct.call!(
        @product_form.serializable_hash.merge(ushaser: current_user)
      )

      @product = context.product.decorate
      render action: :show, status: :created, location: api_v1_product_path(context.product)
    else
      render json: { error: "Product parameters are not valid", errors: @product_form.errors }, status: :not_acceptable
    end
  end

  def show; end

private

  def product
    @product ||= Product.find(params[:id]).decorate
  end

  def set_search_params
    @search = SearchParams.new(query_params.except(:page_name))
  end

  def product_create_params
    params.require(:product).permit(
      :name, :brand, :category, :subcategory, :product_code,
      :webpage, :description, :country_of_origin, :barcode,
      :authenticity, :when_placed_on_market, :has_markings, markings: []
    )
  end

  def query_params
    params.permit(:q, :sort_by, :sort_dir, :direction, :category, :retired_status, :page_name)
  end

  def count_to_display
    params[:category].blank? && params[:q].blank? && [nil, "active"].include?(params[:retired_status]) ? Product.not_retired.count : @pagy.count
  end
end
