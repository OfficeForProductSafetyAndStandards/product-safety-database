namespace :opensearch do
  desc "re-index opensearch model"
  task index: :environment do
    [Investigation, Product, Business].each do |model|
      model.__elasticsearch__.import force: true, refresh: :wait
    end
  end
end
