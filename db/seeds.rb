require "faker"

# This solves the issue described by https://github.com/rails/rails/issues/35812
ActiveJob::Base.queue_adapter = Rails.application.config.active_job.queue_adapter

def create_blob(filename, title: nil, description: nil)
  ActiveStorage::Blob.create_and_upload!(
    io: File.open(filename),
    filename:,
    content_type: "image/jpeg",
    metadata: {
      title: title || filename,
      description:,
      updated: Time.zone.now.iso8601
    }
  )
end

organisation = Organisation.create!(name: "Seed Organisation")
team = Team.create!(name: "Seed Team", team_recipient_email: "seed@example.com", "organisation": organisation, country: "country:GB")
team.roles.create!(name: "opss")

# Users
user = User.find_by(email: "seed_user@example.com") || User.create!(
  name: "Seed User",
  email: "seed_user@example.com",
  password: "testpassword",
  password_confirmation: "testpassword",
  organisation:,
  team:,
)

# Products
country_codes = Country.all.map(&:second)
all_seed_files = Dir.glob("./db/seed_files/*")
hazard_types = Rails.application.config.hazard_constants["hazard_type"]
product_categories = Rails.application.config.product_constants["product_category"]

10.times do
  product_params = {
    country_of_origin: country_codes.sample,
    brand: Faker::Commerce.brand,
    description: Faker::Hipster.sentence(word_count: 20),
    authenticity: %w[counterfeit genuine unsure].sample,
    product_code: Faker::Alphanumeric.alpha(number: 10),
    name: Faker::Commerce.product_name,
    category: product_categories.sample,
    subcategory: Faker::Appliance.equipment,
    webpage: Faker::TvShows::SiliconValley.url,
    has_markings: "markings_unknown"
  }

  product = CreateProduct.call!(
    product_params.merge({ user: })
  ).product

  product.update!(owning_team: team)

  blob = create_blob(all_seed_files.sample, title: Faker::Commerce.product_name, description: Faker::Hipster.sentence(word_count: 10))
  product.documents.attach(blob)
  AuditActivity::Document::Add.from(blob, product)
end

# Notifications
10.times do
  notification = Investigation::Notification.new(
    description: Faker::Hipster.sentence(word_count: 20),
    is_closed: false,
    user_title: Faker::Hipster.sentence(word_count: 2),
    hazard_type: hazard_types.sample,
    product_category: product_categories.sample,
    is_private: false,
    hazard_description: Faker::Games::Zelda.location,
    non_compliant_reason: nil,
    complainant_reference: nil,
    owner_team: team
  )

  notification.complainant = Complainant.new(
    name: Faker::TvShows::TheThickOfIt.character,
    phone_number: Faker::PhoneNumber.phone_number,
    email_address: Faker::Internet.email,
    complainant_type: Faker::TvShows::TheThickOfIt.department,
    other_details: Faker::TvShows::TheThickOfIt.position
  )

  notification = CreateNotification.call!(notification:, user:).notification

  product = Product.all.sample
  AddProductToNotification.call!(notification:, product:, user:)

  if rand(100) > 50
    blob = create_blob(all_seed_files.sample, title: Faker::Commerce.product_name, description: Faker::Hipster.sentence(word_count: 10))
    notification.documents.attach(blob)
    AuditActivity::Document::Add.from(blob, notification)
  end

  next unless rand(100) > 30

  blob = create_blob(all_seed_files.sample, title: Faker::Commerce.product_name, description: Faker::Hipster.sentence(word_count: 10))
  notification.documents.attach(blob)
  AuditActivity::Document::Add.from(blob, notification)
end

# Accidents/incidents

severities = UnexpectedEvent.severities.values
usages = UnexpectedEvent.usages.values

10.times do
  investigation_product = InvestigationProduct.all.sample
  accident_params = {
    type: "Accident",
    date: Time.zone.today,
    investigation_product_id: investigation_product.id,
    severity: severities.sample,
    usage: usages.sample,
    is_date_known: true
  }

  AddAccidentOrIncidentToNotification.call!(accident_params.merge(investigation: investigation_product.investigation, user:))
end

10.times do
  investigation_product = InvestigationProduct.all.sample
  incident_params = {
    type: "Incident",
    investigation_product_id: investigation_product.id,
    severity: severities.sample,
    severity_other: "maximum severity",
    usage: usages.sample,
    is_date_known: false
  }

  AddAccidentOrIncidentToNotification.call!(incident_params.merge(investigation: investigation_product.investigation, user:))
end

# Risk assessments
risk_levels = RiskAssessment.risk_levels.values
10.times do
  investigation_product = InvestigationProduct.all.sample

  risk_assessment_params = {
    assessed_on: Time.zone.today,
    risk_level: risk_levels.sample,
    investigation_product_ids: [investigation_product.id]
  }

  AddRiskAssessmentToNotification.call!(risk_assessment_params.merge(notification: investigation_product.investigation, user:, assessed_by_team_id: Team.find_by(name: "Seed Team").id))
  RiskAssessment.first.risk_assessment_file.attach(create_blob(all_seed_files.sample, title: "Fork close up"))
end

# Businesses
relationships = %w[retailer online_seller manufacturer exporter importer fulfillment_house distributor authorised_representative responsible_person]
10.times do
  business_params = {
    trading_name: Faker::TvShows::Seinfeld.business,
    company_number: Faker::Company.ein,
    legal_name: Faker::TvShows::SiliconValley.company
  }

  business = Business.create!(business_params)

  business.locations << Location.new(
    name: Faker::TvShows::Simpsons.location,
    country: country_codes.sample,
    address_line_1: Faker::Address.street_address,
    county: Faker::Address.state,
    postal_code: Faker::Address.postcode,
    phone_number: Faker::PhoneNumber.phone_number,
    address_line_2: Faker::Address.secondary_address,
    city: Faker::Address.city
  )

  business.contacts << Contact.new(
    name: Faker::TvShows::TheThickOfIt.character,
    email: Faker::Internet.email,
    phone_number: Faker::PhoneNumber.phone_number,
    job_title: Faker::TvShows::TheThickOfIt.position
  )
  business.save!

  notification = Investigation.all.sample
  notification.investigation_businesses.create!(business:, relationship: relationships.sample)
end

organisation = Organisation.create!(name: "Office for Product Safety and Standards")
trading_standards = Organisation.create!(name: "Trading Standards")

enforcement = Team.create!(name: "OPSS Enforcement", team_recipient_email: "enforcement@example.com", "organisation": organisation, country: "country:GB")
enforcement.roles.create!(name: "opss")

operational_support = Team.create!(name: "OPSS Operational support unit", team_recipient_email: nil, "organisation": organisation, country: "country:GB")
operational_support.roles.create!(name: "opss")

ts_team = Team.create!(name: "TS team", team_recipient_email: nil, "organisation": trading_standards, country: "country:GB")

Team.create!(name: "OPSS Science and Tech", team_recipient_email: nil, "organisation": organisation, country: "country:GB")
Team.create!(name: "OPSS Trading Standards Co-ordination", team_recipient_email: nil, "organisation": organisation, country: "country:GB")
Team.create!(name: "OPSS Incident Management", team_recipient_email: nil, "organisation": organisation, country: "country:GB")
Team.create!(name: "OPSS Testing", team_recipient_email: nil, "organisation": organisation, country: "country:GB")

unless User.find_by(email: "user@example.com")
  User.create!(
    name: "Test User",
    email: "user@example.com",
    password: "testpassword",
    password_confirmation: "testpassword",
    organisation:,
    mobile_number_verified: true,
    team: enforcement,
    mobile_number: ENV.fetch("TWO_FACTOR_AUTH_MOBILE_NUMBER")
  )
end

unless User.find_by(email: "admin@example.com")
  user2 = User.create!(
    name: "Team Admin",
    email: "admin@example.com",
    password: "testpassword",
    password_confirmation: "testpassword",
    organisation:,
    mobile_number_verified: true,
    team: operational_support,
    mobile_number: ENV.fetch("TWO_FACTOR_AUTH_MOBILE_NUMBER")
  )
  user2.roles.create!(name: "team_admin")
end

unless User.find_by(email: "ts_user@example.com")
  User.create!(
    name: "TS User",
    email: "ts_user@example.com",
    password: "testpassword",
    password_confirmation: "testpassword",
    organisation: trading_standards,
    mobile_number_verified: true,
    team: ts_team,
    mobile_number: ENV.fetch("TWO_FACTOR_AUTH_MOBILE_NUMBER")
  )
end

operational_support_unit = Team.find_by(name: "OPSS Operational support unit")
User.where(team_id: operational_support_unit.id).each do |u|
  u.roles.create!(name: "all_data_exporter")
  u.roles.create!(name: "risk_level_validator")
end

Investigation.reindex

# rubocop:disable Layout/MultilineArrayLineBreaks
marketplaces = ["Amazon", "eBay", "AliExpress", "Wish", "Etsy", "AliBaba", "Asos Marketplace", "Banggood",
                "Bonanza", "Depop", "DesertCart", "Ecrater", "Facebook Marketplace", "Farfetch", "Fishpond",
                "Folksy", "ForDeal", "Fruugo", "Grandado", "Groupon", "Gumtree", "Houzz", "Instagram",
                "Joom", "Light In The Box", "OnBuy", "NotOnTheHighStreet", "Manomano", "PatPat", "Pinterest",
                "Rakuten", "Shein", "Shpock", "Stockx", "Temu", "Vinted", "Wayfair", "Wowcher", "Zalando"]
# rubocop:enable Layout/MultilineArrayLineBreaks

marketplaces.each do |marketplace|
  OnlineMarketplace.create(name: marketplace, approved_by_opss: true)
end
