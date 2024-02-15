class AddPrismRiskAssessmentToNotification
  include Interactor

  delegate :notification,
           :product,
           :prism_risk_assessment,
           to: :context

  def call
    context.fail!(error: "No notification supplied") unless notification.is_a?(Investigation)
    context.fail!(error: "The notification is closed") if notification.is_closed?
    context.fail!(error: "No product supplied") unless product.is_a?(Product)
    context.fail!(error: "The product is retired") if product.retired?
    context.fail!(error: "No PRISM risk assessment supplied") unless prism_risk_assessment.is_a?(PrismRiskAssessment)
    context.fail!(error: "The PRISM risk assessment is not submitted") unless prism_risk_assessment.state == "submitted"

    ActiveRecord::Base.transaction do
      (context.fail!(error: "The PRISM risk assessment is already linked to the notification") and return false) if duplicate_prism_associated_investigation

      # When a PRISM risk assessment is associated with a notification, any direct product associations are deleted
      (context.fail!(error: "The PRISM risk assessment is not intended for the supplied product") and return false) if supplied_product_not_in_scope
      prism_risk_assessment.prism_associated_products.destroy_all

      unless prism_risk_assessment.prism_associated_investigations.create!(investigation_id: notification.id, prism_associated_investigation_products_attributes: [{ product_id: product.id }])
        context.fail!(error: "Error adding PRISM risk assessment to notification")
        false
      end
    end
  end

private

  def duplicate_prism_associated_investigation
    PrismAssociatedInvestigation.joins(:prism_associated_investigation_products).find_by(risk_assessment_id: prism_risk_assessment.id, investigation_id: notification.id, prism_associated_investigation_products: { product_id: product.id })
  end

  def supplied_product_not_in_scope
    directly_associated_product_ids = prism_risk_assessment.prism_associated_products.pluck(:product_id)
    directly_associated_product_ids.present? && directly_associated_product_ids.exclude?(product.id)
  end
end
