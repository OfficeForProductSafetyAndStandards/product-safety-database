class AddCorrectiveActionToNotification
  include Interactor
  include EntitiesToNotify

  delegate :corrective_action, :user, :notification, :document, :date_decided, :business_id, :details, :legislation, :measure_type, :duration, :geographic_scopes, :other_action, :action, :investigation_product_id, :online_recall_information, :has_online_recall_information, to: :context

  def call
    context.fail!(error: "No notification supplied") unless notification.is_a?(Investigation)
    context.fail!(error: "No user supplied") unless user.is_a?(User)

    CorrectiveAction.transaction do
      context.corrective_action = notification.corrective_actions.create!(
        date_decided:,
        business_id:,
        details:,
        legislation:,
        measure_type:,
        duration:,
        geographic_scopes:,
        other_action:,
        action:,
        investigation_product_id:,
        online_recall_information:,
        has_online_recall_information:
      )
      corrective_action.document.attach(document)
      create_audit_activity
      send_notification_email unless context.silent
    end
  end

private

  def create_audit_activity
    metadata = AuditActivity::CorrectiveAction::Add.build_metadata(corrective_action)

    AuditActivity::CorrectiveAction::Add.create!(
      investigation: notification,
      business_id:,
      investigation_product_id: investigation_product.id,
      added_by_user: user,
      metadata:
    )
  end

  def investigation_product
    InvestigationProduct.find(investigation_product_id)
  end

  def send_notification_email
    return unless notification.sends_notifications?

    email_recipients_for_team_with_access(notification, user).each do |recipient|
      NotifyMailer.notification_updated(
        notification.pretty_id,
        recipient.name,
        recipient.email,
        "Corrective action was added to the notification by #{user.decorate.display_name(viewer: recipient)}.",
        "Notification updated"
      ).deliver_later
    end
  end
end
