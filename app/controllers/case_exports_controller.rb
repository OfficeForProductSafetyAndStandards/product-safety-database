class CaseExportsController < ApplicationController
  include InvestigationsHelper

  before_action :set_search_params, only: %i[generate]

  def generate
    authorize Investigation, :export?

    investigation_ids = search_for_investigations.records.ids

    case_export = CaseExport.create!
    CaseExportJob.perform_later(investigation_ids, case_export.id, current_user)

    redirect_to investigations_path(q: params[:q]), flash: { success: "Your case export is being prepared. You will receive an email when your export is ready to download." }
  end

  def show
    authorize Investigation, :export?

    @case_export = CaseExport.find(params[:id])
  end
end
