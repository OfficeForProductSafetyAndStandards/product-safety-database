class ChangeCaseVisibility
  include Interactor
  include EntitiesToNotify

  delegate :investigation, :new_visibility, :rationale, :user, to: :context

  def call
    context.fail!(error: "No investigation supplied") unless investigation.is_a?(Investigation)
    context.fail!(error: "No visibility supplied") if new_visibility.nil?
    context.fail!(error: "No user supplied") unless user.is_a?(User)

    investigation.is_private = private?

    return if investigation.changes.none?

    ActiveRecord::Base.transaction do
      investigation.save!
      create_audit_activity_for_case_visibility_changed
    end

    send_notification_email
  end

private

  def create_audit_activity_for_case_visibility_changed
    metadata = activity_class.build_metadata(investigation, rationale)

    activity_class.create!(
      added_by_user: user,
      investigation:,
      title: nil,
      body: nil,
      metadata:
    )
  end

  def activity_class
    AuditActivity::Investigation::UpdateVisibility
  end

  def send_notification_email
    return unless investigation.sends_notifications?

    email_recipients_for_case_owner(investigation).each do |recipient|
      NotifyMailer.investigation_updated(
        investigation.pretty_id,
        recipient.name,
        recipient.email,
        email_body(recipient),
        email_subject
      ).deliver_later
    end
  end

  def email_subject
    I18n.t("change_case_visibility.email_subject_text", case_type: email_case_type, visibility: email_visibility)
  end

  def email_body(viewer = nil)
    user_name = user.decorate.display_name(viewer:)
    I18n.t(
      "change_case_visibility.email_update_text",
      case_type: email_case_type,
      name: user_name,
      visibility: email_visibility
    )
  end

  def email_case_type
    "Notification"
  end

  def private?
    new_visibility == "restricted"
  end

  def email_visibility
    private? ? "restricted" : "unrestricted"
  end
end
