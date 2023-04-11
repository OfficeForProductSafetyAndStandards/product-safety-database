module Investigations
  class UpdateCaseRiskLevelFromRiskAssessmentController < ApplicationController
    def show
      @investigation = Investigation.find_by!(pretty_id: params[:investigation_pretty_id])

      authorize @investigation, :update?

      @risk_assessment = @investigation.risk_assessments.find(params[:risk_assessment_id])

      @update_risk_level_from_risk_assessment_form = UpdateRiskLevelFromRiskAssessmentForm.new

      @investigation = @investigation.decorate
      @risk_assessment = @risk_assessment.decorate
    end

    def update
      @investigation = Investigation.find_by!(pretty_id: params[:investigation_pretty_id])

      authorize @investigation, :update?

      @risk_assessment = @investigation.risk_assessments.find(params[:risk_assessment_id]).decorate

      @update_risk_level_from_risk_assessment_form = UpdateRiskLevelFromRiskAssessmentForm.new(form_params)

      @investigation = @investigation.decorate

      return render :show unless @update_risk_level_from_risk_assessment_form.valid?

      if @update_risk_level_from_risk_assessment_form.update_case_risk_level_to_match_investigation
        ChangeCaseRiskLevel.call!(
          investigation: @investigation,
          user: current_user,
          risk_level: @risk_assessment.risk_level,
          custom_risk_level: @risk_assessment.custom_risk_level
        )
      end

      redirect_to investigation_supporting_information_index_path(@investigation), flash: { success: "The supporting information was updated" }
    end

  private

    def form_params
      params.fetch(:update_risk_level_from_risk_assessment_form, {}).permit(:update_case_risk_level_to_match_investigation)
    end
  end
end
