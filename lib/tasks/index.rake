namespace :elasticsearch do
  desc "re-index elasticsearch model"
  task index: :environment do
    [Investigation, Product, Business].each do |model|
      model.__elasticsearch__.import force: true, refresh: :wait
    end
  end
end
