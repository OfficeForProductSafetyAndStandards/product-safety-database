class ChangeOverseasRegulator
  include Interactor
  include EntitiesToNotify

  delegate :investigation, :is_from_overseas_regulator, :overseas_regulator_country, :user, to: :context

  def call
    context.fail!(error: "No investigation supplied") unless investigation.is_a?(Investigation)
    context.fail!(error: "No user supplied") unless user.is_a?(User)

    assign_overseas_regulator
    return if investigation.changes.none?

    ActiveRecord::Base.transaction do
      investigation.save!
      create_audit_activity_for_overseas_regulator_changed
    end

    send_notification_email(investigation, user)
  end

private

  def create_audit_activity_for_overseas_regulator_changed
    metadata = activity_class.build_metadata(investigation)

    activity_class.create!(
      added_by_user: user,
      investigation:,
      metadata:
    )
  end

  def activity_class
    AuditActivity::Investigation::ChangeOverseasRegulator
  end

  def assign_overseas_regulator
    country = is_from_overseas_regulator ? overseas_regulator_country : nil
    investigation.assign_attributes(is_from_overseas_regulator:, overseas_regulator_country: country)
  end

  def send_notification_email(investigation, user)
    return unless investigation.sends_notifications?

    email_recipients_for_team_with_access(investigation, user).each do |entity|
      email = entity.is_a?(Team) ? entity.team_recipient_email : entity.email
      NotifyMailer.investigation_updated(
        investigation.pretty_id,
        entity.name,
        email,
        "#{user.name} (#{user.team.name}) edited overseas regulator on the case.",
        "Overseas regulator edited for Case"
      ).deliver_later
    end
  end
end
