class Investigations::ViewCorrectiveActionsController < ApplicationController
  def show
    @investigation = Investigation.find_by!(pretty_id: params[:investigation_pretty_id])
    authorize @investigation, :view_non_protected_details?
    @corrective_action = @investigation.corrective_actions.find(params[:id])

    render "investigations/corrective_actions/show"
  end
end
