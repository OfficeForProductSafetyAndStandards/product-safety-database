class HardDeleteDraftNotificationsJob < ApplicationJob
  def perform
    return unless Flipper.enabled?(:submit_notification_reminder)

    Investigation::Notification.hard_delete_old_drafts!
  end
end
