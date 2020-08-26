class ChangeCaseSummary
  include Interactor

  delegate :investigation, :summary, :old_summary, :user, to: :context

  def call
    context.fail!(error: "No investigation supplied") unless investigation.is_a?(Investigation)
    context.fail!(error: "No summary supplied") unless summary.is_a?(String)
    context.fail!(error: "No user supplied") unless user.is_a?(User)

    context.old_summary = investigation.description

    return if old_summary == summary

    ActiveRecord::Base.transaction do
      investigation.update!(description: summary)
      create_audit_activity_for_case_summary_changed
    end

    send_notification_email
  end

private

  def create_audit_activity_for_case_summary_changed
    metadata = activity_class.build_metadata(summary, old_summary)

    activity_class.create!(
      source: UserSource.new(user: user),
      investigation: investigation,
      title: nil,
      body: nil,
      metadata: metadata
    )
  end

  def activity_class
    AuditActivity::Investigation::UpdateSummary
  end

  def send_notification_email
    entities_to_notify.each do |recipient|
      NotifyMailer.investigation_updated(
        investigation.pretty_id,
        recipient.name,
        recipient.email,
        email_body(recipient),
        "#{investigation.case_type.upcase_first} summary updated"
      ).deliver_later
    end
  end

  # Notify the case owner, unless it is the same user/team performing the change
  def entities_to_notify
    entities = [investigation.owner] - [user, user.team]

    entities.map { |entity|
      return entity.users.active if entity.is_a?(Team) && !entity.email

      entity
    }.flatten.uniq
  end

  def email_body(viewer = nil)
    user_name = user.decorate.display_name(viewer: viewer)
    "#{investigation.case_type.upcase_first} summary was updated by #{user_name}."
  end
end
