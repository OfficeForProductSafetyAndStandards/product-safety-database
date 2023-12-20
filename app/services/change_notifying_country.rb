class ChangeNotifyingCountry
  include Interactor
  include EntitiesToNotify

  delegate :investigation, :notifying_country_uk, :notifying_country_overseas, :overseas_or_uk, :user, to: :context

  def call
    context.fail!(error: "No investigation supplied") unless investigation.is_a?(Investigation)
    context.fail!(error: "No user supplied") unless user.is_a?(User)
    context.fail!(error: "No selection made") if overseas_or_uk.blank?
    context.fail!(error: "No country selected") if overseas_or_uk == "uk" && notifying_country_uk.blank?
    context.fail!(error: "No country selected") if overseas_or_uk == "overseas" && notifying_country_overseas.blank?

    assign_country
    return if investigation.changes.none?

    ActiveRecord::Base.transaction do
      investigation.save!
      create_audit_activity_for_notifying_country_changed
    end

    send_notification_email(investigation, user)
  end

private

  def create_audit_activity_for_notifying_country_changed
    metadata = activity_class.build_metadata(investigation)

    activity_class.create!(
      added_by_user: user,
      investigation:,
      metadata:
    )
  end

  def activity_class
    AuditActivity::Investigation::ChangeNotifyingCountry
  end

  def assign_country
    investigation.assign_attributes(notifying_country: notifying_country_uk) if overseas_or_uk == "uk"
    investigation.assign_attributes(notifying_country: notifying_country_overseas) if overseas_or_uk == "overseas"
  end

  def send_notification_email(investigation, user)
    return unless investigation.sends_notifications?

    email_recipients_for_team_with_access(investigation, user).each do |entity|
      email = entity.is_a?(Team) ? entity.team_recipient_email : entity.email
      NotifyMailer.investigation_updated(
        investigation.pretty_id,
        entity.name,
        email,
        "#{user.name} (#{user.team.name}) edited notifying country on the notification.",
        "Notifying country edited for notification"
      ).deliver_later
    end
  end
end
