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

    create_audit_activity
    send_notification_email(investigation, user)
  end

private

  def audit_activity_metadata
    AuditActivity::Alert::Add.build_metadata(alert, user_count)
  end

  def create_audit_activity
    activity = AuditActivity::Alert::Add.create!(
      metadata: audit_activity_metadata,
      source: UserSource.new(user: User.current),
      investigation: investigation
    )
  end

  def source
    UserSource.new(user: user)
  end

  def send_notification_email(investigation, _user)
    email_recipients_for_case_owner.each do |recipient|
      NotifyMailer.investigation_updated(
        investigation.pretty_id,
        recipient.name,
        recipient.email,
        email_update_text(recipient),
        email_subject
      ).deliver_later
    end
  end

  def email_update_text(viewer = nil)
    "Email details added to the #{investigation.case_type.upcase_first} by #{source&.show(viewer)}."
  end
end
