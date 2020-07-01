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

      @investigation.risk_level = @risk_level_form.risk_level.presence

      if @investigation.risk_level_changed?
        action = @investigation.risk_level_was.nil? ? "set" : "changed"
        @investigation.save!
        flash[:success] = I18n.t(".success", scope: "investigations.risk_level", action: action, case_type: @investigation.case_type)
      end

      redirect_to investigation_path(@investigation)
    end
  end
end
