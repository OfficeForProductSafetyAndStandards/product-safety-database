class AddTeamToNotification
  include Interactor

  delegate :collaboration, :user, :notification, :team, :collaboration_class, :message, to: :context

  def call
    context.fail!(error: "No notification supplied") unless notification.is_a?(Investigation)
    context.fail!(error: "No team supplied") unless team.is_a?(Team)
    context.fail!(error: "No user supplied") unless user.is_a?(User)

    begin
      ActiveRecord::Base.transaction do
        context.collaboration = collaboration_class.create!(
          investigation: notification,
          collaborator: team,
          added_by_user: user,
          message:
        )

        create_activity_for_team_added!
      end

      send_notification_email unless context.silent
      notification.reindex
    rescue ActiveRecord::RecordNotUnique
      # Collaborator already added, so return successful but without notifying the team
      # or creating an audit log.
    end
  end

private

  def entities_to_notify
    return [team] if team.email.present?

    team.users.active
  end

  def send_notification_email
    return unless notification.sends_notifications?

    entities_to_notify.each do |entity|
      NotifyMailer.team_added_to_notification_email(
        notification:,
        team:,
        added_by_user: user,
        message:,
        to_email: entity.email
      ).deliver_later
    end
  end

  def activity_class
    AuditActivity::Investigation::TeamAdded
  end

  def create_activity_for_team_added!
    metadata = activity_class.build_metadata(collaboration, message)

    activity_class.create!(
      added_by_user: user,
      investigation: notification,
      metadata:
    )
  end
end
