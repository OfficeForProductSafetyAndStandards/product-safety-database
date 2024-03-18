class ProductExportsController < ApplicationController
  include ProductsHelper

  def generate
    product_export = ProductExport.create!(params: product_export_params, user: current_user)
    ProductExportJob.perform_later(product_export)
    ahoy.track "Generated product export", { product_export_id: product_export.id }
    redirect_to products_path(q: params[:q]), flash: { success: "Your product export is being prepared. You will receive an email when your export is ready to download." }
  end

  def show
    @product_export = ProductExport.find_by!(id: params[:id], user: current_user)
  end
end
