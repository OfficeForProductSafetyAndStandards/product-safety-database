module Investigations
  class RiskValidationsController < ApplicationController
    include UrlHelper
    def update
      @investigation = Investigation.find_by!(pretty_id: params.require(:investigation_pretty_id)).decorate
      #TODO authorize @investigation, :update?

      @risk_validation_form = RiskValidationForm.new(params.require(:investigation).permit(:is_risk_validated))
      return render :edit unless @risk_validation_form.valid?

      result = ChangeRiskValidation.call!(investigation: @investigation, is_risk_validated: @risk_validation_form.is_risk_validated, user: current_user)

      if result.changes_made
        flash[:success] = "Updated all that stuff"
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
  end
end
