class ChangeNotifyingCountry
  include Interactor
  include EntitiesToNotify

  delegate :investigation, :country, :user, to: :context

  def call
    context.fail!(error: "No investigation supplied") unless investigation.is_a?(Investigation)
    context.fail!(error: "No user supplied") unless user.is_a?(User)

    context.changes_made = false

    assign_country
    return if investigation.changes.none?

    ActiveRecord::Base.transaction do
      investigation.save!
      create_audit_activity_for_notifying_country_changed
    end

    context.changes_made = true

    send_notification_email(investigation, user)
  end

private

  def create_audit_activity_for_notifying_country_changed
    metadata = activity_class.build_metadata(investigation)

    activity_class.create!(
      source: user_source,
      investigation: investigation,
      metadata: metadata
    )
  end

  def activity_class
    AuditActivity::Investigation::ChangeNotifyingCountry
  end

  def assign_country
    investigation.assign_attributes(notifying_country: country)
  end

  def user_source
    @user_source ||= UserSource.new(user: user)
  end

  def send_notification_email(investigation, user)
    email_recipients_for_team_with_access(investigation, user).each do |entity|
      email = entity.is_a?(Team) ? entity.team_recipient_email : entity.email
      NotifyMailer.investigation_updated(
        investigation.pretty_id,
        entity.name,
        email,
        "#{user.name} (#{user.team.name}) edited notifying country on the #{investigation.case_type}.",
        "Notifying country edited for #{investigation.case_type.upcase_first}"
      ).deliver_later
    end
  end
end
