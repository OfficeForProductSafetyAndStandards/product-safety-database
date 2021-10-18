class ProductExportsController < ApplicationController
  include ProductsHelper
  helper_method :sort_column, :sort_direction

  before_action :set_search_params, only: %i[generate]

  def generate
    authorize Product, :export?

    # TODO: move this query to the job once we are satisfied that this is working well.
    product_ids = search_for_products.ids
    product_export = ProductExport.create!
    ProductExportJob.perform_later(product_ids, product_export, current_user)
    redirect_to products_path(q: params[:q]), flash: { success: "Your product export is being prepared. You will receive an email when your export is ready to download." }
  end

  def show
    authorize Product, :export?

    @product_export = ProductExport.find(params[:id])
  end
end
