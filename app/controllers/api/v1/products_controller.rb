class Api::V1::ProductsController < Api::BaseController
  include ProductsHelper
  before_action :product, only: :show
  before_action :set_search_params, only: %i[index]

  def index
    @results = search_for_products(20)
    @count = count_to_display
    @products = ProductDecorator.decorate_collection(@results)
  end

  def show; end

private

  def product
    @product ||= Product.find(params[:id]).decorate
  end

  def set_search_params
    @search = SearchParams.new(query_params.except(:page_name))
  end

  def query_params
    params.permit(:q, :sort_by, :sort_dir, :direction, :category, :retired_status, :page_name)
  end

  def count_to_display
    params[:category].blank? && params[:q].blank? && [nil, "active"].include?(params[:retired_status]) ? Product.not_retired.count : @results.total_count
  end
end
