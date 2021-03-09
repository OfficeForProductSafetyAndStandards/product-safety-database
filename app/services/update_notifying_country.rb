class UpdateNotifyingCountry
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

    # send_notification_email
  end

private

  def create_audit_activity_for_notifying_country_changed
    metadata = activity_class.build_metadata(investigation)

    activity_class.create!(
      source: UserSource.new(user: user),
      investigation: investigation,
      metadata: metadata
    )
  end

  def activity_class
    AuditActivity::Investigation::UpdateNotifyingCountry
  end

  def assign_country
    investigation.assign_attributes(notifying_country: country)
  end

  # def send_notification_email
  #   email_recipients_for_team_with_access(investigation, user).each do |entity|
  #     email = entity.is_a?(Team) ? entity.team_recipient_email : entity.email
  #     NotifyMailer.risk_validation_updated(
  #       email: email,
  #       updater: user,
  #       name: entity.name,
  #       investigation: investigation,
  #       action: change_action.to_s,
  #     ).deliver_later
  #   end
  # end
end
