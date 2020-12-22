class AddCorrectiveActionToCase
  include Interactor
  include EntitiesToNotify

  delegate :corrective_action, :user, :investigation, :document, :date_decided, :business_id, :details, :legislation, :measure_type, :duration, :geographic_scope, :other_action, :action, :product_id, :has_online_recall_information, to: :context

  def call
    context.fail!(error: "No investigation supplied") unless investigation.is_a?(Investigation)
    context.fail!(error: "No user supplied") unless user.is_a?(User)

    CorrectiveAction.transaction do
      context.corrective_action = investigation.corrective_actions.create!(
        date_decided: date_decided,
        business_id: business_id,
        details: details,
        legislation: legislation,
        measure_type: measure_type,
        duration: duration,
        geographic_scope: geographic_scope,
        other_action: other_action,
        action: action,
        product_id: product_id,
        has_online_recall_information: has_online_recall_information
      )
      corrective_action.document.attach(document)
      create_audit_activity
    end
  end

private

  def create_audit_activity
    metadata = AuditActivity::CorrectiveAction::Add.build_metadata(corrective_action)
    AuditActivity::CorrectiveAction::Add.create(
      investigation: investigation, business: business, product: product, source: UserSource(user: user)
    )
  end
end
