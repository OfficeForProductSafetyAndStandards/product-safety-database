class BusinessExportsController < ApplicationController
  include BusinessesHelper

  def generate
    authorize Business, :export?

    business_export = BusinessExport.create!(params: business_export_params, user: current_user)
    BusinessExportJob.perform_later(business_export)
    ahoy.track "Generated business export", { business_export_id: business_export.id }

    redirect_to businesses_path(q: params[:q]), flash: { success: "Your business export is being prepared. You will receive an email when your export is ready to download." }
  end

  def show
    authorize Business, :export?

    @business_export = BusinessExport.find_by!(id: params[:id], user: current_user)
  end
end
