class BusinessExportsController < ApplicationController
  include BusinessesHelper

  def generate
    authorize Business, :export?

    Sentry.capture_exception "Testing the new Sentry DSN"

    business_export = BusinessExport.create!(params: business_export_params, user: current_user)
    BusinessExportJob.perform_later(business_export)

    redirect_to businesses_path(q: params[:q]), flash: { success: "Your business export is being prepared. You will receive an email when your export is ready to download." }
  end

  def show
    authorize Business, :export?

    @business_export = BusinessExport.find_by!(id: params[:id], user: current_user)
  end
end
