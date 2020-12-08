module Investigations
  class RiskValidationsController < ApplicationController
    include UrlHelper
    def update
      @investigation = Investigation.find_by!(pretty_id: params.require(:investigation_pretty_id)).decorate
      #TODO authorize @investigation, :update?

      @risk_validation_form = RiskValidationForm.new(is_risk_validated: is_risk_validated, risk_validated_by: current_user.team.name, risk_validated_at: Date.current)
      
      return render :edit unless @risk_validation_form.valid?

      result = ChangeRiskValidation.call!(investigation: @investigation,
                                          is_risk_validated: @risk_validation_form.is_risk_validated,
                                          risk_validated_at: @risk_validation_form.risk_validated_at,
                                          risk_validated_by: @risk_validation_form.risk_validated_by,
                                          user: current_user)

      if result.changes_made
        flash[:success] = "Case risk level validated"
      end

      redirect_to investigation_path(@investigation)
    end

    def edit
      @investigation = Investigation.find_by(pretty_id: params["investigation_pretty_id"])
      @risk_validation_form = RiskValidationForm.new(is_risk_validated: nil)
      @breadcrumbs = build_back_link_to_case
    end

  private

    def set_success_flash_message(result)
      return if result.change_action.blank?

      flash[:success] = I18n.t(".success.#{result.change_action}",
                               scope: "investigations.risk_level",
                               level: result.updated_risk_level.downcase)
    end

    def is_risk_validated
      params.dig :investigation, :is_risk_validated
    end
  end
end
