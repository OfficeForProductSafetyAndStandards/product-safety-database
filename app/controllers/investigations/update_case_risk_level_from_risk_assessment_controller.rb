module Investigations
  class UpdateCaseRiskLevelFromRiskAssessmentController < Investigations::BaseController
    before_action :set_investigation
    before_action :authorize_investigation_updates
    before_action :set_investigation_breadcrumbs

    def show
      @risk_assessment = @investigation_object.risk_assessments.find(params[:risk_assessment_id])
      @update_risk_level_from_risk_assessment_form = UpdateRiskLevelFromRiskAssessmentForm.new
      @risk_assessment = @risk_assessment.decorate
    end

    def update
      @risk_assessment = @investigation_object.risk_assessments.find(params[:risk_assessment_id]).decorate
      @update_risk_level_from_risk_assessment_form = UpdateRiskLevelFromRiskAssessmentForm.new(form_params)
      return render :show unless @update_risk_level_from_risk_assessment_form.valid?

      if @update_risk_level_from_risk_assessment_form.update_case_risk_level_to_match_investigation
        ChangeNotificationRiskLevel.call!(
          notification: @investigation,
          user: current_user,
          risk_level: @risk_assessment.risk_level
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
