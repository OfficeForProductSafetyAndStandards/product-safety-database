class SoftDeleteDraftNotificationsJob < ApplicationJob
  def perform
    return unless Flipper.enabled?(:submit_notification_reminder)

    Investigation::Notification.soft_delete_old_drafts!
  end
end
