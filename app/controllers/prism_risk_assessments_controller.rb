class PrismRiskAssessmentsController < ApplicationController
  def your_prism_risk_assessments
    authorize PrismRiskAssessment, :index?

    @draft_prism_risk_assessments = PrismRiskAssessment.for_user(current_user).draft.order(updated_at: :desc).page(params[:draft_page]).per(20)
    @submitted_prism_risk_assessments = PrismRiskAssessment.submitted.order(updated_at: :desc).page(params[:submitted_page]).per(20)
    @page_name = "your_prism_risk_assessments"

    render "prism_risk_assessments/index"
  end

  def add_to_case
    return redirect_to your_prism_risk_assessments_path if params[:prism_risk_assessment_id].blank? || (params[:investigation_pretty_id].blank? && request.post?)

    @prism_risk_assessment = PrismRiskAssessment.find(params[:prism_risk_assessment_id])
    # Find all submitted PRISM risk assessments that are associated with the chosen product
    # either directly or via a case that is not the current case.
    @related_investigations = Investigation
      .left_joins(:investigation_products, prism_associated_investigations: :prism_associated_investigation_products)
      .where.missing(:prism_associated_investigations)
      .or(Investigation.where.not(prism_associated_investigations: { prism_associated_investigation_products: { product_id: @prism_risk_assessment.product_id } }))
      .where(investigation_products: { product_id: @prism_risk_assessment.product_id })
      .where(is_closed: false)
      .order(updated_at: :desc)
      .decorate

    if request.post?
      investigation = Investigation.find_by!(pretty_id: params[:investigation_pretty_id])
      product = Product.find(@prism_risk_assessment.product_id)

      if AddPrismRiskAssessmentToCase.call(investigation:, product:, prism_risk_assessment: @prism_risk_assessment)
        redirect_to investigation_path(params[:investigation_pretty_id]), flash: { success: "The #{@prism_risk_assessment.name} risk assessment has been added to the case." }
      else
        render :add_to_case
      end
    end
  end
end
