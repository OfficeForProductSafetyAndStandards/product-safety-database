class PrismRiskAssessmentsController < ApplicationController
  def your_prism_risk_assessments
    authorize PrismRiskAssessment, :index?

    # TODO(ruben): search for PRISM risk assessments here
    @draft_risk_assessments_count = 0
    @draft_risk_assessments = []
    @submitted_risk_assessments_count = 0
    @submitted_risk_assessments = []
    @page_name = "your_prism_risk_assessments"

    render "prism_risk_assessments/index"
  end
end
