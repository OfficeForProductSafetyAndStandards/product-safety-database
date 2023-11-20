class Api::V1::ProductsController < Api::BaseController
  before_action :product, only: :show

  def index; end

  def show; end

  private

  def product
    @product ||= Product.find(params[:id]).decorate
  end
end
