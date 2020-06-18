class Investigations::CorrectiveActionsController < ApplicationController
  def show
    @investigation = Investigation.find_by!(pretty_id: params[:investigation_pretty_id])
    authorize @investigation, :view_non_protected_details?
    @corrective_action = @investigation.corrective_actions.find(params[:id]).decorate
  end
end
