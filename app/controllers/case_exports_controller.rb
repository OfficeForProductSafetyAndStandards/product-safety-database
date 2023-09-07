class CaseExportsController < ApplicationController
  include InvestigationsHelper

  def generate
    authorize Investigation, :export?

    case_export = CaseExport.create!(params: case_export_params, user: current_user)
    CaseExportJob.perform_later(case_export)

    redirect_to investigations_path(q: params[:q]), flash: { success: "Your case export is being prepared. You will receive an email when your export is ready to download." }
  end

  def show
    authorize Investigation, :export?

    @case_export = CaseExport.find_by!(id: params[:id], user: current_user)
  end
end
