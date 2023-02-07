namespace :products do
  desc "Backfill investigation_products investigation_closed_at field"
  task backfill_owner: :environment do
    puts "Backfilling owning_team_id for products"
    BackfillProductOwner.call
  end
end
