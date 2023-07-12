class PrismRiskAssessmentsController < ApplicationController
  def your_prism_risk_assessments
    authorize PrismRiskAssessment, :index?

    @draft_prism_risk_assessments = PrismRiskAssessment.for_user(current_user).draft.page(params[:draft_page]).per(20)
    @submitted_prism_risk_assessments = PrismRiskAssessment.for_user(current_user).submitted.page(params[:submitted_page]).per(20)
    @page_name = "your_prism_risk_assessments"

    render "prism_risk_assessments/index"
  end
end
