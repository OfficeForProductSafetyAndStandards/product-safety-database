class Investigations::CorrectiveActionsController < ApplicationController
  def show
    @investigation = Investigation.find_by!(pretty_id: params[:investigation_pretty_id])
    authorize @investigation, :view_non_protected_details?
    @corrective_action = @investigation.corrective_actions.find(params[:id]).decorate
  end

  def edit
    @investigation = Investigation.find_by!(pretty_id: params[:investigation_pretty_id])
    authorize @investigation, :view_non_protected_details?
    @corrective_action = @investigation.corrective_actions.find(params[:id]).decorate
  end

  def update
    @investigation = Investigation.find_by!(pretty_id: params[:investigation_pretty_id])
    authorize @investigation, :view_non_protected_details?
    @corrective_action = @investigation.corrective_actions.find(params[:id])

    result = UpdateCorrectiveAction.call!(
      corrective_action: @corrective_action,
      corrective_actions_params: corrective_actions_params,
      user: current_user
    )
    return redirect_to [@investigation, result.corrective_action] if result.success?

    render [@investigation, @corrective_action]
  end

private

  def corrective_actions_params
    params.require(:corrective_action).permit(
      :product_id,
      :business_id,
      :legislation,
      :summary,
      :details,
      :related_file,
      :measure_type,
      :duration,
      :geographic_scope
    )
  end
end
