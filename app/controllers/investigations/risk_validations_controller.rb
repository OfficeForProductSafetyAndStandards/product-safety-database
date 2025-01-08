module Investigations
  class RiskValidationsController < ApplicationController
    include UrlHelper
    def update
      @investigation = Investigation.find_by!(pretty_id: params.require(:investigation_pretty_id)).decorate
      authorize @investigation, :risk_level_validation?

      @risk_validation_form = RiskValidationForm.new(is_risk_validated: investigation_params["is_risk_validated"], risk_validated_by: current_user.team.name,
                                                     risk_validated_at: Date.current, risk_validation_change_rationale:,
                                                     previous_risk_validated_at: @investigation.risk_validated_at)

      return render :edit unless @risk_validation_form.valid?

      result = ChangeNotificationRiskValidation.call!(@risk_validation_form.serializable_hash.merge(notification: @investigation, user: current_user))

      if result.changes_made
        success_message = @risk_validation_form.is_risk_validated ? "validated_success_message" : "validation_removed_success_message"
        flash[:success] = t("investigations.risk_validation.#{success_message}")
      end

      redirect_to investigation_path(@investigation)
    end

    def edit
      @investigation = Investigation.find_by(pretty_id: params["investigation_pretty_id"])
      authorize @investigation, :risk_level_validation?

      @currently_not_validated = currently_not_validated?
      @risk_validation_form = RiskValidationForm.new(is_risk_validated: is_risk_validated_value)
    end

  private

    def investigation_params
      params.require(:investigation).permit(:is_risk_validated)
    end

    def risk_validation_change_rationale
      params.dig :investigation, :risk_validation_change_rationale
    end

    def currently_not_validated?
      @investigation.has_had_risk_level_validated_before? && !@investigation.risk_level_currently_validated?
    end

    def is_risk_validated_value
      return unless @investigation.has_had_risk_level_validated_before?

      @investigation.risk_level_currently_validated?
    end
  end
end
