namespace :products do
  desc "Marks the given user as deleted, assigning their investigations to their team"
  task backfill_when_placed_on_market: :environment do
    Product.where(when_placed_on_market: nil).update_all(when_placed_on_market: 'before_2021')
  end
end
