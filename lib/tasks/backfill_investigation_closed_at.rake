namespace :investigations do
  desc "Backfill investigation_products investigation_closed_at field"
  task backfill_investigation_closed_at: :environment do
    closed_investigations = Investigation.includes(:investigation_products).where.not(date_closed: nil)

    puts "Backfilling date closed for #{closed_investigations.count} investigation_products"

    closed_investigations.each do |investigation|
      investigation.investigation_products.each do |investigation_product|
        investigation_product.update!(investigation_closed_at: investigation.date_closed) if investigation_product.investigation_closed_at.nil?
      end
    end
  end
end
