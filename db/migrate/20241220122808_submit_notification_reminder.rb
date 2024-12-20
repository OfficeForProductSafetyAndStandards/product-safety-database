class SubmitNotificationReminder < ActiveRecord::Migration[7.1]
  def up
    Flipper.enable(:submit_notification_reminder)
  end

  def down
    Flipper.disable(:submit_notification_reminder)
  end
end
