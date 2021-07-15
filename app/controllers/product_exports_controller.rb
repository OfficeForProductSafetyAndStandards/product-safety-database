class ProductExportsController < ApplicationController
  include ProductsHelper
  helper_method :sort_column, :sort_direction

  before_action :set_search_params, only: %i[index]

  # GET /products/1/edit
  def generate
    @products = search_for_products(Product.count, [:investigations, :test_results, corrective_actions: [:business], risk_assessments: [:assessed_by_business, :assessed_by_team]]).sort
    product_export = ProductExport.create
    ProductExportWorker.perform_later(@products, product_export.id, current_user)
    redirect_to products_path, flash: { success: "Your product export is being prepared. You will receive an email when your export is ready to download." }
  end

  def index
    @product_export = ProductExport.last
  end

  def show
    @product_export = ProductExport.find(params[:id])
  end
end
