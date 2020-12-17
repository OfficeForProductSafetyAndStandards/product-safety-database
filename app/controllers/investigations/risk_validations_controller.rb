module Investigations
  class RiskValidationsController < ApplicationController
    include UrlHelper
    def update
      @investigation = Investigation.find_by!(pretty_id: params.require(:investigation_pretty_id)).decorate

      @risk_validation_form = RiskValidationForm.new(is_risk_validated: is_risk_validated, risk_validated_by: current_user.team.name,
                                                     risk_validated_at: Date.current, risk_validation_change_rationale: risk_validation_change_rationale,
                                                     previous_risk_validated_at: @investigation.risk_validated_at)

      return render :edit unless @risk_validation_form.valid?

      result = ChangeRiskValidation.call!(investigation: @investigation,
                                          is_risk_validated: @risk_validation_form.is_risk_validated,
                                          risk_validated_at: @risk_validation_form.risk_validated_at,
                                          risk_validated_by: @risk_validation_form.risk_validated_by,
                                          risk_validation_change_rationale: @risk_validation_form.risk_validation_change_rationale,
                                          user: current_user)

      if result.changes_made
        success_message = @risk_validation_form.is_risk_validated ? "validated_success_message" : "validation_removed_success_message"
        flash[:success] = t("investigations.risk_validation.#{success_message}")
      end

      redirect_to investigation_path(@investigation)
    end

    def edit
      @investigation = Investigation.find_by(pretty_id: params["investigation_pretty_id"])
      @risk_validation_form = RiskValidationForm.new(is_risk_validated: is_risk_validated_value)
      @breadcrumbs = build_back_link_to_case
    end

  private

    def is_risk_validated
      params.dig :investigation, :is_risk_validated
    end

    def risk_validation_change_rationale
      params.dig :investigation, :risk_validation_change_rationale
    end

    def is_risk_validated_value
      return unless @investigation.activities.map(&:type).include? "AuditActivity::Investigation::UpdateRiskLevelValidation"
      @investigation.risk_validated_by ? true : false
    end
  end
end
