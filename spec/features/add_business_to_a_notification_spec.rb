require "rails_helper"

RSpec.feature "Adding and removing business to a notification", :with_stubbed_mailer, :with_stubbed_opensearch do
  let(:city)             { Faker::Address.city }
  let(:trading_name)     { Faker::Company.name }
  let(:business_details) { Faker::Company.buzzword }
  let(:company_number)   { SecureRandom.hex }
  let(:address_line_one) { Faker::Address.street_address }
  let(:address_line_two) { Faker::Address.secondary_address }
  let(:postcode)         { Faker::Address.postcode }
  let(:country)          { Country.all.sample.first }
  let(:name)             { Faker::TvShows::TheITCrowd.character }
  let(:email)            { Faker::TvShows::TheITCrowd.email }
  let(:phone_number)     { Faker::PhoneNumber.phone_number  }
  let(:job_title)        { Faker::Job.title }
  let(:user)             { create(:user, :activated) }
  let(:notification)     { create(:notification, creator: user) }
  let(:other_user)       { create(:user, :activated) }

  # rubocop:disable RSpec/LetSetup
  let!(:marketplace_one_business_location) { create(:location) }
  let!(:marketplace_two_business_location) { create(:location) }

  let!(:marketplace_one)   { create(:online_marketplace, :approved) }
  let!(:marketplace_two)   { create(:online_marketplace, :approved) }

  let!(:marketplace_one_business) { create(:business, online_marketplace: marketplace_one, locations: [marketplace_one_business_location]) }
  let!(:marketplace_two_business) { create(:business, online_marketplace: marketplace_two, locations: [marketplace_two_business_location]) }
  let!(:unapproved_marketplace) { create(:online_marketplace) }
  # rubocop:enable RSpec/LetSetup

  before do
    ChangeNotificationOwner.call!(notification:, owner: user.team, user:)

    create_list(:online_marketplace, 2)
  end

  scenario "Adding a business" do
    sign_in user
    visit "/cases/#{notification.pretty_id}/businesses"

    click_link "Add business"
    expect_to_have_notification_breadcrumbs

    # Don't select a business type
    click_on "Continue"

    expect_to_be_on_investigation_add_business_type_page
    expect_to_have_notification_breadcrumbs
    expect(page).to have_error_summary("Select a business type")

    expect(page).to have_unchecked_field("Retailer")
    expect(page).to have_unchecked_field("Manufacturer")
    expect(page).to have_unchecked_field("Exporter")
    expect(page).to have_unchecked_field("Importer")
    expect(page).to have_unchecked_field("Online seller")
    expect(page).to have_unchecked_field("Online marketplace")
    expect(page).to have_unchecked_field("Fulfillment house")
    expect(page).to have_unchecked_field("Distributor")

    choose "Retailer"
    click_on "Continue"

    expect_to_be_on_investigation_add_business_details_page
    expect_to_have_notification_breadcrumbs

    click_on "Save"
    expect(page).to have_error_summary("Trading name cannot be blank")
    expect_to_have_notification_breadcrumbs

    within_fieldset "Name and company number" do
      fill_in "Registered or legal name", with: business_details
      fill_in "Company number",           with: company_number
    end

    within_fieldset "Official address" do
      fill_in "Building and street line 1 of 2",    with: address_line_one
      fill_in "Building and street line 2 of 2",    with: address_line_two
      fill_in "Town or city",        with: city
      fill_in "Postcode",            with: postcode
    end

    within_fieldset "Contacts" do
      fill_in "Name", with: name
      fill_in "Email",                         with: email
      fill_in "Telephone",                     with: phone_number
      fill_in "Job title or role description", with: job_title
    end

    click_on "Save"

    expect(page).to have_error_summary("Trading name cannot be blank")

    within_fieldset "Name and company number" do
      fill_in "Trading name", with: trading_name
    end

    click_on "Save"

    expect(page).to have_error_summary("Country cannot be blank")

    within_fieldset "Official address" do
      select country, from: "business-locations-country-field-error"
    end

    click_on "Save"

    expect_to_be_on_notification_businesses_page
    expect(page).not_to have_error_messages
    expect_to_have_notification_breadcrumbs

    within("section##{trading_name.parameterize}") do
      expect(page.find("dt", text: "Trading name")).to have_sibling("dd", text: trading_name)
      expect(page.find("dt", text: "Legal name")).to have_sibling("dd", text: business_details)
      expect(page.find("dt", text: "Company number")).to have_sibling("dd", text: company_number)
    end

    # Check that adding  the business was recorded in the
    # activity log for the notification.
    click_link "Activity"
    expect(page).to have_text("Business added")
    expect_to_have_notification_breadcrumbs

    expect(page.find("h3", text: "Business added"))
      .to have_sibling(".govuk-body", text: "Role: retailer")
  end

  scenario "Adding an approved online marketplace business with selection" do
    sign_in user

    # start journey
    visit "/cases/#{notification.pretty_id}/businesses"
    click_link "Add business"

    # validation
    expect_to_be_on_investigation_add_business_type_page
    expect_to_have_notification_breadcrumbs
    expect(page).to have_unchecked_field("Retailer")
    expect(page).to have_unchecked_field("Manufacturer")
    expect(page).to have_unchecked_field("Exporter")
    expect(page).to have_unchecked_field("Importer")
    expect(page).to have_unchecked_field("Online seller")
    expect(page).to have_unchecked_field("Online marketplace")
    expect(page).to have_unchecked_field("Fulfillment house")
    expect(page).to have_unchecked_field("Distributor")
    expect(page).to have_unchecked_field("Authorised representative")

    # choose the online marketplace
    choose "Online marketplace"
    expect(page).to have_unchecked_field(marketplace_one.name)
    choose marketplace_one.name
    click_on "Continue"

    # Uses stored marketplace business & location, does not ask for details
    expect_to_be_on_notification_businesses_page
    expect(page).not_to have_error_messages
    expect_to_have_notification_breadcrumbs

    # validate the summary page after adding the business
    expect(page).to have_text("These are the businesses included in the notification.")
    expect(page.find("dt", text: "Online marketplace")).to have_sibling("dd", text: marketplace_one.name)

    # Check that adding  the business was recorded in the
    # activity log for the notification.
    click_link "Activity"
    expect_to_have_notification_breadcrumbs
    expect(page.find("h3", text: "Business added"))
      .to have_sibling(".govuk-body", text: "Role: online_marketplace")
  end

  scenario "Adding an approved online marketplace business without selection produces error" do
    sign_in user
    visit "/cases/#{notification.pretty_id}/businesses"

    click_link "Add business"

    expect_to_be_on_investigation_add_business_type_page
    expect_to_have_notification_breadcrumbs

    expect(page).to have_unchecked_field("Retailer")
    expect(page).to have_unchecked_field("Manufacturer")
    expect(page).to have_unchecked_field("Exporter")
    expect(page).to have_unchecked_field("Importer")
    expect(page).to have_unchecked_field("Online seller")
    expect(page).to have_unchecked_field("Online marketplace")
    expect(page).to have_unchecked_field("Fulfillment house")
    expect(page).to have_unchecked_field("Distributor")
    expect(page).to have_unchecked_field("Authorised representative")

    # Don't select a business type
    click_on "Continue"

    expect(page).to have_error_summary("Select a business type")
  end

  scenario "Adding a EU authorised rep business" do
    sign_in user
    visit "/cases/#{notification.pretty_id}/businesses"

    click_link "Add business"
    expect_to_have_notification_breadcrumbs

    # Don't select a business type
    click_on "Continue"

    expect_to_be_on_investigation_add_business_type_page
    expect_to_have_notification_breadcrumbs
    expect(page).to have_error_summary("Select a business type")

    expect(page).to have_unchecked_field("Retailer")
    expect(page).to have_unchecked_field("Manufacturer")
    expect(page).to have_unchecked_field("Exporter")
    expect(page).to have_unchecked_field("Importer")
    expect(page).to have_unchecked_field("Online seller")
    expect(page).to have_unchecked_field("Online marketplace")
    expect(page).to have_unchecked_field("Fulfillment house")
    expect(page).to have_unchecked_field("Distributor")
    expect(page).to have_unchecked_field("Authorised representative")

    choose "Authorised representative"
    expect(page).to have_unchecked_field("UK Authorised representative")
    expect(page).to have_unchecked_field("EU Authorised representative")
    choose "EU Authorised representative"

    click_on "Continue"

    expect_to_be_on_investigation_add_business_details_page
    expect_to_have_notification_breadcrumbs

    within_fieldset "Name and company number" do
      fill_in "Trading name", with: trading_name
    end

    within_fieldset "Official address" do
      select "France", from: "business-locations-country-field"
    end

    click_on "Save"

    expect_to_be_on_notification_businesses_page
    expect(page).not_to have_error_messages
    expect_to_have_notification_breadcrumbs

    within("section##{trading_name.parameterize}") do
      expect(page.find("dt", text: "Trading name")).to have_sibling("dd", text: trading_name)
      expect(page.find("dt", text: "Business type")).to have_sibling("dd", text: "EU Authorised representative")
    end
  end

  scenario "Adding an 'other' online marketplace business" do
    sign_in user
    visit "/cases/#{notification.pretty_id}/businesses"

    click_link "Add business"
    expect_to_have_notification_breadcrumbs

    # Don't select a business type
    click_on "Continue"

    expect_to_be_on_investigation_add_business_type_page
    expect_to_have_notification_breadcrumbs
    expect(page).to have_error_summary("Select a business type")

    choose "Online marketplace"
    expect(page).to have_unchecked_field(marketplace_one.name)
    expect(page).to have_unchecked_field(marketplace_two.name)

    fill_in "Other online platform", with: "Another amazing marketplace"

    click_on "Continue"

    expect_to_be_on_investigation_add_business_details_page
    expect_to_have_notification_breadcrumbs

    within_fieldset "Name and company number" do
      fill_in "Trading name", with: trading_name
    end

    within_fieldset "Official address" do
      select "France", from: "business-locations-country-field"
    end

    click_on "Save"

    expect_to_be_on_notification_businesses_page
    expect(page).not_to have_error_messages
    expect_to_have_notification_breadcrumbs

    within("section##{trading_name.parameterize}") do
      expect(page.find("dt", text: "Trading name")).to have_sibling("dd", text: trading_name)
      expect(page.find("dt", text: "Online marketplace")).to have_sibling("dd", text: "Another amazing marketplace")
    end

    # Check that adding  the business was recorded in the
    # activity log for the notification.
    click_link "Activity"
    expect(page).to have_text("Business added")
    expect_to_have_notification_breadcrumbs

    expect(page.find("h3", text: "Business added"))
      .to have_sibling(".govuk-body", text: "Role: online_marketplace")
  end

  scenario "Not being able to add a business to another team's case" do
    sign_in other_user
    visit "/cases/#{notification.pretty_id}/businesses"
    expect(page).not_to have_link("Add a business")
  end
end
