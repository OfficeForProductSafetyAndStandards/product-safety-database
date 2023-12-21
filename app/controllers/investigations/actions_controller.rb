module Investigations
  class ActionsController < ApplicationController
    def index
      @investigation = Investigation.find_by!(pretty_id: params[:investigation_pretty_id]).decorate
      @actions_form = InvestigationActionsForm.new(
        investigation: @investigation,
        current_user:
      )
    end

    def create
      @investigation = Investigation.find_by!(pretty_id: params[:investigation_pretty_id]).decorate
      authorize @investigation, :update?

      @actions_form = InvestigationActionsForm.new(
        investigation: @investigation,
        current_user:,
        investigation_action: actions_params[:investigation_action]
      )

      return render(:index) if @actions_form.invalid?

      redirect_to path_for_action(@actions_form.investigation_action)
    end

  private

    def path_for_action(action)
      case action
      when "close_case"
        close_investigation_status_path(@investigation)
      when "reopen_case"
        reopen_investigation_status_path(@investigation)
      when "change_case_owner"
        new_investigation_ownership_path(@investigation)
      when "change_case_visibility"
        investigation_visibility_path(@investigation)
      when "change_case_risk_level"
        investigation_risk_level_path(@investigation)
      end
    end

    def actions_params
      return {} if params[:investigation_actions_form].blank?

      params.require(:investigation_actions_form).permit(:investigation_action)
    end
  end
end
