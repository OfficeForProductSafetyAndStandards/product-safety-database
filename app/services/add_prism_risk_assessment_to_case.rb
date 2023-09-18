class AddPrismRiskAssessmentToCase
  include Interactor

  delegate :investigation,
           :product,
           :prism_risk_assessment,
           to: :context

  def call
    context.fail!(error: "No investigation supplied") unless investigation.is_a?(Investigation)
    context.fail!(error: "The investigation is closed") if investigation.is_closed?
    context.fail!(error: "No product supplied") unless product.is_a?(Product)
    context.fail!(error: "The product is retired") if product.retired?
    context.fail!(error: "No PRISM risk assessment supplied") unless prism_risk_assessment.is_a?(PrismRiskAssessment)
    context.fail!(error: "The PRISM risk assessment is not submitted") unless prism_risk_assessment.state == "submitted"

    ActiveRecord::Base.transaction do
      (context.fail!(error: "The PRISM risk assessment is already linked to the case") and return false) if duplicate_prism_associated_investigation

      # When a PRISM risk assessment is associated with a case, any direct product associations are deleted
      prism_risk_assessment.prism_associated_products.destroy_all
      unless prism_risk_assessment.prism_associated_investigations.create!(investigation_id: investigation.id, prism_associated_investigation_products_attributes: [{ product_id: product.id }])
        context.fail!(error: "Error adding PRISM risk assessment to case")
        false
      end
    end
  end

private

  def duplicate_prism_associated_investigation
    PrismAssociatedInvestigation.joins(:prism_associated_investigation_products).find_by(risk_assessment_id: prism_risk_assessment.id, investigation_id: investigation.id, prism_associated_investigation_products: { product_id: product.id })
  end
end
