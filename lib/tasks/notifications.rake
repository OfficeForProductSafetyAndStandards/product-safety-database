namespace :notifications do
  desc "Re-index notifications"
  task index: :environment do
    Investigation.reindex
  end

  desc "Mark all draft notifications as submitted"
  task mark_as_submitted: :environment do
    Investigation::Notification.where(state: "draft").update_all(state: "submitted")
  end
end
