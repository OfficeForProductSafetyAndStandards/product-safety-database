class CaseExportsController < ApplicationController
  include InvestigationsHelper

  before_action :set_search_params, only: %i[generate]

  def generate
    authorize Investigation, :export?

    # TODO: move this query to the job once we are satisfied that this is working well.
    answer = search_for_investigations
    investigations = answer.records(includes: [:complainant, :products, :owner_team, :owner_user, { creator_user: :team }]).to_a

    case_export = CaseExport.create!
    CaseExportJob.perform_later(investigations, case_export.id, current_user)
    redirect_to investigations_path(q: params[:q]), flash: { success: "Your case export is being prepared. You will receive an email when your export is ready to download." }
  end

  def show
    authorize Investigation, :export?

    @case_export = CaseExport.find(params[:id])
  end
end
