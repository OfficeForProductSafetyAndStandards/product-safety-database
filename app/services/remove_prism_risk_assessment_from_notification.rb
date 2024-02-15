class RemovePrismRiskAssessmentFromNotification
  include Interactor

  delegate :notification,
           :prism_risk_assessment,
           to: :context

  def call
    context.fail!(error: "No notification supplied") unless notification.is_a?(Investigation)
    context.fail!(error: "The notification is closed") if notification.is_closed?
    context.fail!(error: "No PRISM risk assessment supplied") unless prism_risk_assessment.is_a?(PrismRiskAssessment)
    context.fail!(error: "The PRISM risk assessment is not submitted") unless prism_risk_assessment.state == "submitted"

    ActiveRecord::Base.transaction do
      prism_associated_investigation = prism_risk_assessment.prism_associated_investigations.find_by(investigation_id: notification.id)
      products = prism_associated_investigation.prism_associated_investigation_products.map(&:product)
      prism_associated_investigation.destroy!

      if prism_risk_assessment.prism_associated_investigations.blank? && prism_risk_assessment.prism_associated_products.blank?
        # Re-associate the PRISM risk assessment with the original products if it is not associated to any other products or
        # notifications to prevent it being orphaned.
        products.each { |product| prism_risk_assessment.prism_associated_products.create!(product:) }
      end
    end
  end
end
