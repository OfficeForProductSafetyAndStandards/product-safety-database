class AddCorrectiveActionToCase
  include Interactor
  include EntitiesToNotify

  delegate :corrective_action, :user, :investigation, :document, :date_decided, :business_id, :details, :legislation, :measure_type, :duration, :geographic_scope, :other_action, :action, :product_id, :online_recall_information, :has_online_recall_information, :changes, to: :context

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
        online_recall_information: online_recall_information,
        has_online_recall_information: has_online_recall_information
      )
      corrective_action.document.attach(document)
      create_audit_activity
      send_notification_email
    end
  end

private

  def create_audit_activity
    metadata = AuditActivity::CorrectiveAction::Add.build_metadata(corrective_action, changes)

    AuditActivity::CorrectiveAction::Add.create!(
      investigation: investigation,
      business_id: business_id,
      product_id: product_id,
      source: source,
      metadata: metadata
    )
  end

  def source
    @source ||= UserSource.new(user: user)
  end

  def send_notification_email
    email_recipients_for_team_with_access(investigation, user).each do |recipient|
      NotifyMailer.investigation_updated(
        investigation.pretty_id,
        recipient.name,
        recipient.email,
        "Corrective action was added to the #{investigation.case_type.upcase_first} by #{source.show(recipient)}.",
        "#{investigation.case_type.upcase_first} updated"
      ).deliver_later
    end
  end
end
