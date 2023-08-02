namespace :opensearch do
  desc "re-index opensearch model"
  task index: :environment do
    Investigation.__elasticsearch__.import scope: "not_deleted", force: true, refresh: :wait
  end
end
