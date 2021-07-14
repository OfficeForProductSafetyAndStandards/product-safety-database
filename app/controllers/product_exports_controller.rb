class ProductExportsController < ApplicationController
  include ProductsHelper
  helper_method :sort_column, :sort_direction

  before_action :set_search_params, only: %i[index]

  # GET /products/1/edit
  def generate
    @products = search_for_products(Product.count, [:investigations, :test_results, corrective_actions: [:business], risk_assessments: [:assessed_by_business, :assessed_by_team]]).sort
    product_export = ProductExport.create
    ProductExportWorker.perform_async(@products, product_export.id)
  end
end
