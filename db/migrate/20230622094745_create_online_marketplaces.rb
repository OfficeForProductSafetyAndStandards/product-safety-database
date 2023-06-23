# rubocop:disable Layout/MultilineArrayLineBreaks
class CreateOnlineMarketplaces < ActiveRecord::Migration[7.0]
  def change
    safety_assured do
      create_table :online_marketplaces do |t|
        t.string :name
        t.boolean :approved_by_opss

        t.timestamps
      end

      add_index :online_marketplaces, :name, unique: true, name: "index_online_marketplaces_on_name"

      marketplaces = ["Amazon", "eBay", "AliExpress", "Wish", "Etsy", "AliBaba", "Asos Marketplace", "Banggood",
                      "Bonanza", "Depop", "DesertCart", "Ecrater", "Facebook Marketplace", "Farfetch", "Fishpond",
                      "Folksy", "ForDeal", "Fruugo", "Grandado", "Groupon", "Gumtree", "Houzz", "Instagram",
                      "Joom", "Light In The Box", "OnBuy", "NotOnTheHighStreet", "Manomano", "PatPat", "Pinterest",
                      "Rakuten", "Shein", "Shpock", "Stockx", "Temu", "Vinted", "Wayfair", "Wowcher", "Zalando"]

      marketplaces.each do |marketplace|
        OnlineMarketplace.create(name: marketplace, approved_by_opss: true)
      end
    end
  end
end
# rubocop:enable Layout/MultilineArrayLineBreaks
