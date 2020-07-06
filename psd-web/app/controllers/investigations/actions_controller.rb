module Investigations
  class ActionsController < ApplicationController
    def index
      @investigation = Investigation.find_by!(pretty_id: params[:investigation_pretty_id]).decorate
      @actions_form = InvestigationActionsForm.new(
        investigation: @investigation,
        current_user: current_user
      )
    end

    def create
      @investigation = Investigation.find_by!(pretty_id: params[:investigation_pretty_id]).decorate
      authorize @investigation, :update?

      @actions_form = InvestigationActionsForm.new(
        investigation: @investigation,
        current_user: current_user,
        investigation_action: params[:investigation_action]
      )

      return render(:index) if @actions_form.invalid?

      redirect_to path_for_action(@actions_form.investigation_action)
    end

  private

    def path_for_action(action)
      case action
      when "change_case_status"
        status_investigation_path(@investigation)
      when "change_case_owner"
        new_investigation_ownership_path(@investigation)
      when "change_case_visibility"
        visibility_investigation_path(@investigation)
      when "send_email_alert"
        new_investigation_alert_path(@investigation)
      end
    end
  end
end
