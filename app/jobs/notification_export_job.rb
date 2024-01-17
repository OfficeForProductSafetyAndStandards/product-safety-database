class NotificationExportJob < ApplicationJob
  def perform(notification_export)
    notification_export.export!

    NotifyMailer.notification_export(
      email: notification_export.user.email,
      name: notification_export.user.name,
      notification_export:
    ).deliver_later
  rescue StandardError => e
    Sentry.capture_exception(e)
    raise
  end
end
