class RemoveTeamFromNotification
  include Interactor

  delegate :collaboration, :user, :message, to: :context

  def call
    context.fail!(error: "No collaboration supplied") unless collaboration.is_a?(Collaboration::Access)
    context.fail!(error: "Collaboration type cannot be removed") unless collaboration.changeable?
    context.fail!(error: "No user supplied") unless user.is_a?(User)

    ActiveRecord::Base.transaction do
      collaboration.destroy!
      create_audit_activity_for_team_deleted!
    end

    send_notification_email unless context.silent
    notification.reindex
  end

private

  def team
    collaboration.collaborator
  end

  def notification
    collaboration.investigation
  end

  def activity_class
    AuditActivity::Investigation::TeamDeleted
  end

  def create_audit_activity_for_team_deleted!
    metadata = activity_class.build_metadata(team, message)

    activity_class.create!(
      added_by_user: user,
      investigation: notification,
      metadata:
    )
  end

  def entities_to_notify
    return [team] if team.email.present?

    team.users.active
  end

  def send_notification_email
    return unless notification.sends_notifications?

    entities_to_notify.each do |entity|
      NotifyMailer.team_removed_from_notification_email(
        message:,
        notification:,
        team_deleted: team,
        user_who_deleted: user,
        to_email: entity.email
      ).deliver_later
    end
  end
end
