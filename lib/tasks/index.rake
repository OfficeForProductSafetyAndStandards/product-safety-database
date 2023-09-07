namespace :opensearch do
  desc "re-index opensearch model"
  task index: :environment do
    Investigation.reindex
  end
end
