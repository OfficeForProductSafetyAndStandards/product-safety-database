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

      @risk_level_form = RiskLevelForm.new(params.require(:investigation).permit(:risk_level, :risk_level_other))
      return render :show unless @risk_level_form.valid?

      result = ChangeCaseRiskLevel.call!(investigation: @investigation, user: current_user, risk_level: @risk_level_form.risk_level.presence)
      if result.change_action.present?
        flash[:success] = I18n.t(".success.#{result.change_action}", scope: "investigations.risk_level", level: @investigation.risk_level&.downcase)
      end

      redirect_to investigation_path(@investigation)
    end
  end
end
