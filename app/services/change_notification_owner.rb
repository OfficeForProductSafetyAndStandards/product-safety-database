class ChangeNotificationOwner
  include Interactor
  include NotifyHelper

  delegate :notification, :owner, :rationale, :user, :old_owner, to: :context

  def call
    context.fail!(error: "No notification supplied") unless notification.is_a?(Investigation)
    context.fail!(error: "No owner supplied") unless owner.is_a?(User) || owner.is_a?(Team)
    context.fail!(error: "No user supplied") unless user.is_a?(User)

    notification.reload # force cached associations to be reloaded

    context.old_owner = notification.owner

    return if old_owner == owner

    ActiveRecord::Base.transaction do
      unless owner.team == notification.owner_team
        notification.owner_team_collaboration.swap_to_edit_access!
      end

      old_collaboration = notification
                            .collaboration_accesses
                            .changeable
                            .find_by(collaborator: owner.team)

      (old_collaboration || owner).own!(notification)

      notification.reindex

      create_audit_activity_for_notification_owner_changed
    end

    notification.reload
    send_notification_email unless context.silent
  end

private

  def create_audit_activity_for_notification_owner_changed
    metadata = activity_class.build_metadata(owner, rationale)

    activity_class.create!(
      added_by_user: user,
      investigation: notification,
      title: nil,
      body: nil,
      metadata:
    )
  end

  def activity_class
    AuditActivity::Investigation::UpdateOwner
  end

  def send_notification_email
    return unless notification.sends_notifications?

    entities_to_notify.each do |recipient|
      NotifyMailer.investigation_updated(
        notification.pretty_id,
        recipient.name,
        recipient.email,
        email_body(recipient),
        "Owner changed for notification"
      ).deliver_later
    end
  end

  # Notify the new owner, and the old one if it's not the user making the change
  def entities_to_notify
    entities = [owner]
    entities << old_owner if old_owner != user

    entities.map { |entity|
      return entity.users.active if entity.is_a?(Team) && !entity.email

      entity
    }.flatten.uniq
  end

  def email_body(viewer = nil)
    user_name = user.decorate.display_name(viewer:)
    body = "Owner changed on notification to #{owner.decorate.display_name(viewer:)} by #{user_name}."
    body << "\n\nMessage from #{user_name}: #{inset_text_for_notify(rationale)}" if rationale
    body
  end
end
