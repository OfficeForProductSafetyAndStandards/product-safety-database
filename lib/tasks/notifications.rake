namespace :notifications do
  desc "Re-index notifications"
  task index: :environment do
    Investigation.reindex
  end
end
