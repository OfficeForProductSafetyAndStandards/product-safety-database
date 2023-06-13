module Investigations
  class RiskLevelController < ApplicationController
    def show
      @investigation = Investigation.find_by!(pretty_id: params.require(:investigation_pretty_id)).decorate
      authorize @investigation, :update?

      @risk_level_form = RiskLevelForm.new(risk_level: @investigation.risk_level)
    end

    def update
      @investigation = Investigation.find_by!(pretty_id: params.require(:investigation_pretty_id)).decorate
      authorize @investigation, :update?

      @risk_level_form = RiskLevelForm.new(params.require(:investigation).permit(:risk_level))
      return render :show unless @risk_level_form.valid?

      result = ChangeCaseRiskLevel.call!(
        @risk_level_form.attributes.merge(investigation: @investigation, user: current_user)
      )
      set_success_flash_message(result)
      redirect_to investigation_path(@investigation)
    end

  private

    def set_success_flash_message(result)
      return if result.change_action.blank?

      flash[:success] = I18n.t(".success.#{result.change_action}",
                               scope: "investigations.risk_level",
                               level: result.updated_risk_level.downcase)
    end
  end
end
