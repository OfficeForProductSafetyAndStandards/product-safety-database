class BusinessExportsController < ApplicationController
  include BusinessesHelper

  before_action :set_search_params, only: %i[generate]

  def generate
    authorize Business, :export?

    business_ids = search_for_businesses.records.ids

    business_export = BusinessExport.create!
    BusinessExportJob.perform_later(business_ids, business_export, current_user)

    redirect_to businesses_path(q: params[:q]), flash: { success: "Your business export is being prepared. You will receive an email when your export is ready to download." }
  end

  def show
    authorize Business, :export?

    @business_export = BusinessExport.find(params[:id])
  end
end
