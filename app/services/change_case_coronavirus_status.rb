class ChangeCaseCoronavirusStatus
  include Interactor
  include EntitiesToNotify

  delegate :investigation, :status, :user, to: :context

  def call
    context.fail!(error: "No investigation supplied") unless investigation.is_a?(Investigation)
    context.fail!(error: "No coronavirus status supplied") if status.nil?
    context.fail!(error: "No user supplied") unless user.is_a?(User)

    investigation.assign_attributes(coronavirus_related: status)
    return if investigation.changes.none?

    ActiveRecord::Base.transaction do
      investigation.save!
      create_audit_activity_for_coronavirus_status_changed
    end

    send_notification_email

    context.updated_coronavirus_status = status
  end

private

  def create_audit_activity_for_coronavirus_status_changed
    metadata = activity_class.build_metadata(investigation)

    activity_class.create!(
      source: UserSource.new(user: user),
      investigation: investigation,
      title: nil,
      body: nil,
      metadata: metadata
    )
  end

  def activity_class
    AuditActivity::Investigation::UpdateCoronavirusStatus
  end

  def send_notification_email
    email_recipients_for_case_owner.each do |recipient|
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
    I18n.t("change_case_coronavirus_status.email_subject_text", case_type: investigation.case_type.downcase)
  end

  def email_body(viewer = nil)
    user_name = user.decorate.display_name(viewer: viewer)
    I18n.t(
      "change_case_coronavirus_status.email_update_text.#{investigation.coronavirus_related?}",
      case_type: investigation.case_type.upcase_first,
      name: user_name,
      pretty_id: investigation.pretty_id
    )
  end
end
