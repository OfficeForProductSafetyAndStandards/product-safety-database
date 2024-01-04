class ChangeNotificationPermissionLevelForTeam
  include Interactor

  delegate :existing_collaboration, :new_collaboration_class, :user, :message, :collaboration, to: :context

  def call
    context.fail!(error: "No existing collaboration supplied") unless existing_collaboration.is_a?(Collaboration::Access)
    context.fail!(error: "New collaboration class must be a changeable type") unless new_collaboration_class&.changeable?
    context.fail!(error: "Existing collaboration type cannot be changed") unless existing_collaboration.changeable?
    context.fail!(error: "No user supplied") unless user.is_a?(User)

    ActiveRecord::Base.transaction do
      existing_collaboration.destroy!
      context.collaboration = create_new_collaboration!
      create_audit_activity_for_team_permission_changed!
    end

    send_notification_email
  end

private

  def team
    existing_collaboration.collaborator
  end

  def investigation
    existing_collaboration.investigation
  end

  def create_new_collaboration!
    new_collaboration_class.create!(
      investigation:,
      collaborator: team,
      added_by_user: user,
      message:
    )
  end

  def old_permission
    existing_collaboration.model_name.human
  end

  def new_permission
    new_collaboration_class.model_name.human
  end

  def activity_class
    AuditActivity::Investigation::TeamPermissionChanged
  end

  def create_audit_activity_for_team_permission_changed!
    metadata = activity_class.build_metadata(team, old_permission, new_permission, message)

    activity_class.create!(
      added_by_user: user,
      investigation:,
      metadata:
    )
  end

  def entities_to_notify
    return [team] if team.email.present?

    team.users.active
  end

  def send_notification_email
    return unless investigation.sends_notifications?

    entities_to_notify.each do |entity|
      NotifyMailer.case_permission_changed_for_team(
        message:,
        investigation:,
        team:,
        user:,
        to_email: entity.email,
        old_permission:,
        new_permission:
      ).deliver_later
    end
  end
end
