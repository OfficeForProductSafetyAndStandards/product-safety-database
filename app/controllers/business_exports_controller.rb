class BusinessExportsController < ApplicationController
  include BusinessesHelper

  before_action :set_search_params, only: %i[generate]

  def generate
    results = search_for_businesses.records.includes(:investigations, :locations, :contacts)

    # TODO: move this query to the job once we are satisfied that this is working well.
    business_export = BusinessExport.create!
    BusinessExportJob.perform_later(results, business_export.id, current_user)
    redirect_to busineses_path(q: params[:q]), flash: { success: "Your business export is being prepared. You will receive an email when your export is ready to download." }
  end

  def show
    @business_export = BusinessExport.find(params[:id])
  end
end
