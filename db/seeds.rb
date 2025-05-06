require "faker"

# This solves the issue described by https://github.com/rails/rails/issues/35812
ActiveJob::Base.queue_adapter = Rails.application.config.active_job.queue_adapter

# Helper method to safely create audit activity records
def safe_audit_activity_create(blob, target)
  # Use create! with explicit parameters instead of the .from method
  # This helps avoid SQL injection by using ActiveRecord's parameterization
  AuditActivity::Document::Add.create!(
    document_type: "file",
    metadata: {}, # Use minimal metadata to avoid SQL injection vectors
    blob_id: blob.id,
    created_by: "seed_script",
    updated_at: Time.zone.now,
    created_at: Time.zone.now,
    investigation_id: target.is_a?(Investigation) ? target.id : nil,
    product_id: target.is_a?(Product) ? target.id : nil,
    title: blob.metadata[:title] || "Seed document",
    correspondence_date: Time.zone.now
  )
rescue StandardError => e
  Rails.logger.error("Failed to create audit activity: #{e.message}")
  nil
end

def create_blob(filename, title: nil, description: nil)
  valid_path = File.expand_path(filename)
  seed_files_dir = File.expand_path("./db/seed_files")

  unless valid_path.start_with?(seed_files_dir) && File.exist?(valid_path)
    raise "Invalid seed file: #{filename}"
  end

  sanitized_title = title || File.basename(valid_path)
  sanitized_description = description

  ActiveStorage::Blob.create_and_upload!(
    io: File.open(valid_path),
    filename: File.basename(valid_path),
    content_type: "image/jpeg",
    metadata: {
      title: sanitized_title,
      description: sanitized_description,
      updated: Time.zone.now.iso8601
    }
  )
end

organisation = Organisation.create!(name: "Seed Organisation")
team = Team.create!(name: "Seed Team", team_recipient_email: "seed@example.com", organisation:, country: "country:GB")
team.roles.create!(name: "opss")

# Users
user = User.find_by(email: "seed_user@example.com") || User.create!(
  name: "Seed User",
  email: "seed_user@example.com",
  password: "testpassword",
  password_confirmation: "testpassword",
  organisation:,
  team:,
  mobile_number_verified: true,
  mobile_number: ENV.fetch("TWO_FACTOR_AUTH_MOBILE_NUMBER")
)

user.roles.create!(name: "notification_task_list_user")
user.roles.create!(name: "super_user")
user.roles.create!(name: "team_admin")

# Roles
roles = %w[
  all_data_exporter
  notifying_country_editor
  opss
  team_admin
  super_user
  prism
  risk_level_validator
  restricted_case_viewer
  product_bulk_uploader
  notification_task_list_user
  use_new_search
]

roles.each do |role|
  email = "#{role}@example.com"
  next if User.find_by(email:)

  role_user = User.create!(
    name: role.humanize,
    email:,
    password: "testpassword",
    password_confirmation: "testpassword",
    organisation:,
    team:,
    mobile_number_verified: true,
    mobile_number: ENV.fetch("TWO_FACTOR_AUTH_MOBILE_NUMBER")
  )
  role_user.roles.create!(name: role)
end

# Products
country_codes = Country.all.map(&:second)
all_seed_files = Dir.glob(File.expand_path("./db/seed_files/*")).select { |f| File.file?(f) }
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

  product = CreateProduct.call!(product_params.merge({ user: })).product
  product.update!(owning_team: team)

  next unless all_seed_files.any?

  # Generating random data for the blob
  title = Faker::Commerce.product_name
  description = Faker::Hipster.sentence(word_count: 10)

  # Create the blob with sanitized values
  blob = create_blob(all_seed_files.sample,
                     title: title,
                     description: description)

  # Attach the blob as a document
  product.documents.attach(blob)

  # Use our safer method instead of the problematic one
  safe_audit_activity_create(blob, product)
end

# Notifications
40.times do
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

  if rand(100) > 50 && all_seed_files.any?
    # Generating random data for the blob
    title = Faker::Commerce.product_name
    description = Faker::Hipster.sentence(word_count: 10)

    # Create the blob with sanitized values
    blob = create_blob(all_seed_files.sample,
                       title: title,
                       description: description)

    # Attach the blob as a document
    notification.documents.attach(blob)

    # Use our safer method instead of the problematic one
    safe_audit_activity_create(blob, notification)
  end

  next unless rand(100) > 30 && all_seed_files.any?

  # Generating random data for the blob
  title = Faker::Commerce.product_name
  description = Faker::Hipster.sentence(word_count: 10)

  # Create the blob with sanitized values
  blob = create_blob(all_seed_files.sample,
                     title: title,
                     description: description)

  # Attach the blob as a document
  notification.documents.attach(blob)

  # Use our safer method instead of the problematic one
  safe_audit_activity_create(blob, notification)
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

  AddAccidentOrIncidentToNotification.call!(accident_params.merge(notification: investigation_product.investigation, user:))
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

  AddAccidentOrIncidentToNotification.call!(incident_params.merge(notification: investigation_product.investigation, user:))
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

  next unless all_seed_files.any?

  # Create a safer blob with static known values
  blob = create_blob(all_seed_files.sample, title: "Fork close up")
  RiskAssessment.first.risk_assessment_file.attach(blob)
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

# Duplicate Businesses for Testing
duplicate_business_params = {
  trading_name: "Duplicate Business",
  company_number: "12345678",
  legal_name: "Duplicate Business Ltd"
}

3.times do
  business = Business.create!(duplicate_business_params)

  business.locations << Location.new(
    name: "Duplicate Location",
    country: "GB",
    address_line_1: "123 Fake Street",
    county: "Test County",
    postal_code: "AB12 3CD",
    phone_number: "01234567890",
    address_line_2: "Suite 1",
    city: "Test City"
  )

  business.contacts << Contact.new(
    name: "Duplicate Contact",
    email: "duplicate@example.com",
    phone_number: "01234567890",
    job_title: "Manager"
  )
  business.save!

  notification = Investigation.all.sample
  notification.investigation_businesses.create!(business:, relationship: relationships.sample)
end

# Additional teams and users
organisation = Organisation.create!(name: "Office for Product Safety and Standards")
trading_standards = Organisation.create!(name: "Trading Standards")

enforcement = Team.create!(name: "OPSS Enforcement", team_recipient_email: "enforcement@example.com", organisation:, country: "country:GB")
enforcement.roles.create!(name: "opss")

operational_support = Team.create!(name: "OPSS Operational support unit", team_recipient_email: nil, organisation:, country: "country:GB")
operational_support.roles.create!(name: "opss")

ts_team = Team.create!(name: "TS team", team_recipient_email: nil, organisation: trading_standards, country: "country:GB")

[
  "OPSS Science and Tech",
  "OPSS Trading Standards Co-ordination",
  "OPSS Incident Management",
  "OPSS Testing"
].each do |team_name|
  Team.create!(name: team_name, team_recipient_email: nil, organisation:, country: "country:GB")
end

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

operational_support_unit = Team.find_by!(name: "OPSS Operational support unit")

User.where(team_id: operational_support_unit.id).find_each do |u|
  %w[all_data_exporter risk_level_validator].each do |role_name|
    u.roles.find_or_create_by!(name: role_name)
  end
end

Investigation.reindex

# Online Marketplaces
marketplaces = [
  "Amazon",
  "eBay",
  "AliExpress",
  "Wish",
  "Etsy",
  "AliBaba",
  "Asos Marketplace",
  "Banggood",
  "Bonanza",
  "Depop",
  "DesertCart",
  "Ecrater",
  "Facebook Marketplace",
  "Farfetch",
  "Fishpond",
  "Folksy",
  "ForDeal",
  "Fruugo",
  "Grandado",
  "Groupon",
  "Gumtree",
  "Houzz",
  "Instagram",
  "Joom",
  "Light In The Box",
  "OnBuy",
  "NotOnTheHighStreet",
  "Manomano",
  "PatPat",
  "Pinterest",
  "Rakuten",
  "Shein",
  "Shpock",
  "Stockx",
  "Temu",
  "Vinted",
  "Wayfair",
  "Wowcher",
  "Zalando"
]

marketplaces.each do |marketplace|
  OnlineMarketplace.create(name: marketplace, approved_by_opss: true)
end
