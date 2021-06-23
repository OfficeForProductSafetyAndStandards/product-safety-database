class AddAlert
  include Interactor
  include EntitiesToNotify

  delegate :investigation, :user, :user_count, :summary, :investigation, :description, :alert, to: :context

  def call
    context.fail!(error: "No investigation supplied") unless investigation.is_a?(Investigation)
    context.fail!(error: "No user supplied") unless user.is_a?(User)

    context.alert = Alert.create!(
      description: description,
      summary: summary,
      investigation_id: investigation.id,
    )

    send_alert_emails
    create_audit_activity
  end

private

  def send_alert_emails
    emails = User.active.map(&:email)
    SendAlertJob.perform_later(emails, subject_text: summary, body_text: description)
  end

  def audit_activity_metadata
    AuditActivity::Alert::Add.build_metadata(alert)
  end

  def create_audit_activity
    AuditActivity::Alert::Add.create!(
      metadata: audit_activity_metadata,
      source: UserSource.new(user: User.current),
      investigation: investigation
    )
  end

  def source
    UserSource.new(user: user)
  end
end
