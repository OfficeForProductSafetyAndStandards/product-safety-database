class AssociateBusinessesWithApprovedOnlineMarketplaces < ActiveRecord::Migration[7.0]
  def self.up
    country_uk = "country:GB"
    country_usa = "country:US"
    country_china = "country:CN"
    country_ireland = "country:IE"

    Business.create!(trading_name: "AliBaba", locations: [Location.new(name: "Registered office address", address_line_1: "8th Floor Millbank Tower", address_line_2: "21-24 Millbank", city: "London", postal_code: "SW1P 4QP", country: country_uk)], online_marketplace: marketplace("Alibaba"))
    Business.create!(trading_name: "AliExpress", locations: [Location.new(name: "Registered office address", address_line_1: "Flat B", address_line_2: "13 Dawes Road", city: "London", postal_code: "SW6 7DT", country: country_uk)], online_marketplace: marketplace("AliExpress"))
    Business.create!(trading_name: "Amazon", locations: [Location.new(name: "Registered office address", address_line_1: "1 Principal Place", address_line_2: "Worship Street", city: "London", postal_code: "EC2A 2FA", country: country_uk)], online_marketplace: marketplace("Amazon"))
    Business.create!(trading_name: "Asos Marketplace", locations: [Location.new(name: "Registered office address", address_line_1: "Greater London House", address_line_2: "Hampstead Road", city: "London", postal_code: "NW1 7FB", country: country_uk)], online_marketplace: marketplace("Asos Marketplace"))
    Business.create!(trading_name: "Banggood", locations: [Location.new(name: "Registered office address", address_line_1: "Rm 601 6/F Kimberley House", address_line_2: "35 Kimberley Road, Tsim Sha Tsui Kln", city: "Hong Kong", postal_code: "999077", country: country_china)], online_marketplace: marketplace("Banggood"))
    Business.create!(trading_name: "Bonanza", locations: [Location.new(name: "Registered office address", address_line_1: "42 Newburgh Road", address_line_2: "Acton", city: "London", postal_code: "W3 6DQ", country: country_uk)], online_marketplace: marketplace("Bonanza"))
    Business.create!(trading_name: "Depop", locations: [Location.new(name: "Registered office address", address_line_1: "1 Bartholomew Lane", city: "London", postal_code: "EC2N 2AX", country: country_uk)], online_marketplace: marketplace("Depop"))
    Business.create!(trading_name: "DesertCart", locations: [Location.new(name: "Registered office address", address_line_1: "1-4 Argyll Street", city: "London", postal_code: "W1F 7LD", country: country_uk)], online_marketplace: marketplace("DesertCart"))
    Business.create!(trading_name: "eBay", locations: [Location.new(name: "Registered office address", address_line_1: "Hotham House1 Heron Square", address_line_2: "Richmond Upon Thames", city: "Surrey", postal_code: "TW9 1EJ", country: country_uk)], online_marketplace: marketplace("eBay"))
    Business.create!(trading_name: "Ecrater", locations: [Location.new(name: "Registered office address", address_line_1: "105 Alberti Aisle", address_line_2: "Irvine", city: "California", postal_code: "92614", country: country_usa)], online_marketplace: marketplace("Ecrater"))
    Business.create!(trading_name: "Etsy", locations: [Location.new(name: "Registered office address", address_line_1: "1 Bartholomew Lane", city: "London", postal_code: "EC2N 2AX", country: country_uk)], online_marketplace: marketplace("Etsy"))
    Business.create!(trading_name: "Facebook Marketplace", locations: [Location.new(name: "Registered office address", address_line_1: "10 Brock Street", address_line_2: "Regent's Place", city: "London", postal_code: "NW1 3FG", country: country_uk)], online_marketplace: marketplace("Facebook Marketplace"))
    Business.create!(trading_name: "Farfetch", locations: [Location.new(name: "Registered office address", address_line_1: "The Bower", address_line_2: "211 Old Street", city: "London", postal_code: "EC1V 9NR", country: country_uk)], online_marketplace: marketplace("Farfetch"))
    Business.create!(trading_name: "Fishpond", locations: [Location.new(name: "Registered office address", address_line_1: "26 Bamel Way", address_line_2: "Nexus Ii, Gloucester Business Park", city: "Gloucester", postal_code: "GL3 4BH", country: country_uk)], online_marketplace: marketplace("Fishpond"))
    Business.create!(trading_name: "Folksy", locations: [Location.new(name: "Registered office address", address_line_1: "43 Westbourne Road", city: "Sheffield", postal_code: "S10 2QT", country: country_uk)], online_marketplace: marketplace("Folksy"))
    Business.create!(trading_name: "ForDeal", locations: [Location.new(name: "Registered office address", address_line_1: "Suite 108 Chase Business Centre", address_line_2: "39-41 Chase Side", city: "London", postal_code: "N14 5BP", country: country_uk)], online_marketplace: marketplace("ForDeal"))
    Business.create!(trading_name: "Fruugo", locations: [Location.new(name: "Registered office address", address_line_1: "13 Fountain Street", address_line_2: "Ulverston", city: "Cumbria", postal_code: "LA12 7EQ", country: country_uk)], online_marketplace: marketplace("Fruugo"))
    Business.create!(trading_name: "Grandado", locations: [Location.new(name: "Registered office address", address_line_1: "Office 6", address_line_2: "5A Signal Walk", city: "London", postal_code: "E4 9BW", country: country_uk)], online_marketplace: marketplace("Grandado"))
    Business.create!(trading_name: "Groupon", locations: [Location.new(name: "Registered office address", address_line_1: "Floors 11-12 Aldgate Tower", address_line_2: "2 Leman Street", city: "London", postal_code: "E1 8FA", country: country_uk)], online_marketplace: marketplace("Groupon"))
    Business.create!(trading_name: "Gumtree", locations: [Location.new(name: "Registered office address", address_line_1: "27 Old Gloucester Street", city: "London", postal_code: "WC1N 3AX", country: country_uk)], online_marketplace: marketplace("Gumtree"))
    Business.create!(trading_name: "Houzz", locations: [Location.new(name: "Registered office address", address_line_1: "Suite 2 First Floor", address_line_2: "10 Temple Back", city: "Bristol", postal_code: "BS1 6FL", country: country_uk)], online_marketplace: marketplace("Houzz"))
    Business.create!(trading_name: "Instagram", locations: [Location.new(name: "Registered office address", address_line_1: "10 Brock Street", address_line_2: "Regent's Place", city: "London", postal_code: " NW1 3FG", country: country_uk)], online_marketplace: marketplace("Instagram"))
    Business.create!(trading_name: "Joom", locations: [Location.new(name: "Registered office address", address_line_1: "The Long Lodge", address_line_2: "265 - 269 Kingston Road, Wimbledon", city: "London", postal_code: "SW19 3NW", country: country_uk)], online_marketplace: marketplace("Joom"))
    Business.create!(trading_name: "Light In The Box", locations: [Location.new(name: "Registered office address", address_line_1: "85 Tottenham Court Road", city: "London", postal_code: "W1T 4TQ", country: country_uk)], online_marketplace: marketplace("Light In The Box"))
    Business.create!(trading_name: "Manomano", locations: [Location.new(name: "Registered office address", address_line_1: "32 Delamere Gardens", address_line_2: "Fair Oak", city: "Eastleigh", postal_code: "SO50 7GE", country: country_uk)], online_marketplace: marketplace("Manomano"))
    Business.create!(trading_name: "NotOnTheHighStreet", locations: [Location.new(name: "Registered office address", address_line_1: "First Floor Templeback", address_line_2: "10 Temple Back", city: "Bristol", postal_code: "BS1 6FL", country: country_uk)], online_marketplace: marketplace("NotOnTheHighStreet"))
    Business.create!(trading_name: "OnBuy", locations: [Location.new(name: "Registered office address", address_line_1: "Unit G1, Capital House", address_line_2: "61 Amhurst Road", city: "London", postal_code: "E8 1LL", country: country_uk)], online_marketplace: marketplace("OnBuy"))
    Business.create!(trading_name: "PatPat", locations: [Location.new(name: "Registered office address", address_line_1: "8 High Snoad Wood", address_line_2: "Challock", city: "Ashford", postal_code: "TN25 4DQ", country: country_uk)], online_marketplace: marketplace("PatPat"))
    Business.create!(trading_name: "Pinterest", locations: [Location.new(name: "Registered office address", address_line_1: "100 New Bridge Street", city: "London", postal_code: "EC4V 6JA", country: country_uk)], online_marketplace: marketplace("Pinterest"))
    Business.create!(trading_name: "Rakuten", locations: [Location.new(name: "Registered office address", address_line_1: "Vintners Place", address_line_2: "68 Upper Thames St", city: "London", postal_code: "EC4V 2AF", country: country_uk)], online_marketplace: marketplace("Rakuten"))
    Business.create!(trading_name: "Shein", locations: [Location.new(name: "Registered office address", address_line_1: "35 Ivor Place", address_line_2: "Lower Ground", city: "London", postal_code: "NW1 6EA", country: country_uk)], online_marketplace: marketplace("Shein"))
    Business.create!(trading_name: "Shpock", locations: [Location.new(name: "Registered office address", address_line_1: "C/O A K S Advisers", address_line_2: "14-15 Lower Grosvenor Place", city: "London", postal_code: "SW1W 0EX", country: country_uk)], online_marketplace: marketplace("Shpock"))
    Business.create!(trading_name: "Stockx", locations: [Location.new(name: "Registered office address", address_line_1: "5 New Street Square", city: "London", postal_code: "EC4A 3TW", country: country_uk)], online_marketplace: marketplace("Stockx"))
    Business.create!(trading_name: "Temu", locations: [Location.new(name: "Registered office address", address_line_1: "First Floor", address_line_2: "25 St Stephens Green", city: "Dublin 2", country: country_ireland)], online_marketplace: marketplace("Temu"))
    Business.create!(trading_name: "Vinted", locations: [Location.new(name: "Registered office address", address_line_1: "5 New Street Square", city: "London", postal_code: "EC4A 3TW", country: country_uk)], online_marketplace: marketplace("Vinted"))
    Business.create!(trading_name: "Wayfair", locations: [Location.new(name: "Registered office address", address_line_1: "Fourth Floor, Angel House", address_line_2: "338-446 Goswell Road", city: "London", postal_code: "EC1V 7LQ", country: country_uk)], online_marketplace: marketplace("Wayfair"))
    Business.create!(trading_name: "Wish", locations: [Location.new(name: "Registered office address", address_line_1: "One Sansome Street", address_line_2: "33rd Floor", city: "San Francisco", postal_code: "CA 94104.", country: country_usa)], online_marketplace: marketplace("Light In The Box"))
    Business.create!(trading_name: "Wowcher", locations: [Location.new(name: "Registered office address", address_line_1: "69 Dalston Lane", city: "London", postal_code: "E8 2NG", country: country_uk)], online_marketplace: marketplace("Wowcher"))
    Business.create!(trading_name: "Zalando", locations: [Location.new(name: "Registered office address", address_line_1: "C/O Tradebyte Software Limited Studio 8", address_line_2: "Montpellier Street", city: "Cheltenham", postal_code: "GL50 1SS", country: country_uk)], online_marketplace: marketplace("Zalando"))
  end

  def self.down
    Business.where("online_marketplace_id is not null").destroy_all
  end

private

  def marketplace(name)
    OnlineMarketplace.find_by(name:)
  end
end
