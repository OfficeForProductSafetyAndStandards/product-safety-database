require "rails_helper"

RSpec.feature "Adding and removing business to a case", :with_stubbed_mailer, :with_stubbed_opensearch do
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
  let(:investigation)    { create(:enquiry, creator: user) }
  let(:other_user)       { create(:user, :activated) }

  # rubocop:disable RSpec/LetSetup
  let!(:marketplace_1_business_location) { create(:location) }
  let!(:marketplace_2_business_location) { create(:location) }

  let!(:marketplace_1)   { create(:online_marketplace, :approved) }
  let!(:marketplace_2)   { create(:online_marketplace, :approved) }

  let!(:marketplace_1_business) { create(:business, online_marketplace: marketplace_1, locations: [marketplace_1_business_location]) }
  let!(:marketplace_2_business) { create(:business, online_marketplace: marketplace_2, locations: [marketplace_2_business_location]) }
  let!(:unapproved_marketplace) { create(:online_marketplace) }
  # rubocop:enable RSpec/LetSetup

  before do
    ChangeCaseOwner.call!(investigation:, owner: user.team, user:)

    create_list(:online_marketplace, 2)
  end

  scenario "Adding a business" do
    sign_in user
    visit "/cases/#{investigation.pretty_id}/businesses"

    click_link "Add business"
    expect_to_have_case_breadcrumbs

    # Don't select a business type
    click_on "Continue"

    expect_to_be_on_investigation_add_business_type_page
    expect_to_have_case_breadcrumbs
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
    expect_to_have_case_breadcrumbs

    click_on "Save"
    expect(page).to have_error_summary("Trading name cannot be blank")
    expect_to_have_case_breadcrumbs

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
      select country, from: "Country"
    end

    click_on "Save"

    expect_to_be_on_investigation_businesses_page
    expect(page).not_to have_error_messages
    expect_to_have_case_breadcrumbs

    within("section##{trading_name.parameterize}") do
      expect(page.find("dt", text: "Trading name")).to have_sibling("dd", text: trading_name)
      expect(page.find("dt", text: "Legal name")).to have_sibling("dd", text: business_details)
      expect(page.find("dt", text: "Company number")).to have_sibling("dd", text: company_number)
    end

    # Check that adding  the business was recorded in the
    # activity log for the investigation.
    click_link "Activity"
    expect(page).to have_text("Business added")
    expect_to_have_case_breadcrumbs

    expect(page.find("h3", text: "Business added"))
      .to have_sibling(".govuk-body", text: "Role: retailer")
  end

  scenario "Adding an approved online marketplace business" do
    sign_in user
    visit "/cases/#{investigation.pretty_id}/businesses"

    click_link "Add business"
    expect_to_have_case_breadcrumbs

    # Don't select a business type
    click_on "Continue"

    expect_to_be_on_investigation_add_business_type_page
    expect_to_have_case_breadcrumbs
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

    choose "Online marketplace"
    expect(page).to have_unchecked_field(marketplace_1.name)
    expect(page).to have_unchecked_field(marketplace_2.name)
    expect(page).not_to have_unchecked_field(unapproved_marketplace.name)
    choose marketplace_1.name

    click_on "Continue"

    # Uses stored marketplace business & location, does not ask for details
    expect_to_be_on_investigation_businesses_page
    expect(page).not_to have_error_messages
    expect_to_have_case_breadcrumbs

    within("section##{marketplace_1_business.trading_name.parameterize}") do
      expect(page.find("dt", text: "Online marketplace")).to have_sibling("dd", text: marketplace_1.name)
      expect(page.find("dt", text: "Company number")).to have_sibling("dd", text: marketplace_1_business.company_number)

      expect(page).to have_text(marketplace_1_business_location.address_line_1)
      expect(page).to have_text(marketplace_1_business_location.address_line_2)
    end

    # Check that adding  the business was recorded in the
    # activity log for the investigation.
    click_link "Activity"
    expect(page).to have_text("Business added")
    expect_to_have_case_breadcrumbs

    expect(page.find("h3", text: "Business added"))
      .to have_sibling(".govuk-body", text: "Role: online_marketplace")
  end

  scenario "Adding a EU authorised rep business" do
    sign_in user
    visit "/cases/#{investigation.pretty_id}/businesses"

    click_link "Add business"
    expect_to_have_case_breadcrumbs

    # Don't select a business type
    click_on "Continue"

    expect_to_be_on_investigation_add_business_type_page
    expect_to_have_case_breadcrumbs
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
    expect_to_have_case_breadcrumbs

    within_fieldset "Name and company number" do
      fill_in "Trading name", with: trading_name
    end

    within_fieldset "Official address" do
      select "France", from: "Country"
    end

    click_on "Save"

    expect_to_be_on_investigation_businesses_page
    expect(page).not_to have_error_messages
    expect_to_have_case_breadcrumbs

    within("section##{trading_name.parameterize}") do
      expect(page.find("dt", text: "Trading name")).to have_sibling("dd", text: trading_name)
      expect(page.find("dt", text: "Business type")).to have_sibling("dd", text: "EU Authorised representative")
    end
  end

  scenario "Adding an 'other' online marketplace business" do
    sign_in user
    visit "/cases/#{investigation.pretty_id}/businesses"

    click_link "Add business"
    expect_to_have_case_breadcrumbs

    # Don't select a business type
    click_on "Continue"

    expect_to_be_on_investigation_add_business_type_page
    expect_to_have_case_breadcrumbs
    expect(page).to have_error_summary("Select a business type")

    choose "Online marketplace"
    expect(page).to have_unchecked_field(marketplace_1.name)
    expect(page).to have_unchecked_field(marketplace_2.name)

    fill_in "Other online platform", with: "Another amazing marketplace"

    click_on "Continue"

    expect_to_be_on_investigation_add_business_details_page
    expect_to_have_case_breadcrumbs

    within_fieldset "Name and company number" do
      fill_in "Trading name", with: trading_name
    end

    within_fieldset "Official address" do
      select "France", from: "Country"
    end

    click_on "Save"

    expect_to_be_on_investigation_businesses_page
    expect(page).not_to have_error_messages
    expect_to_have_case_breadcrumbs

    within("section##{trading_name.parameterize}") do
      expect(page.find("dt", text: "Trading name")).to have_sibling("dd", text: trading_name)
      expect(page.find("dt", text: "Online marketplace")).to have_sibling("dd", text: "Another amazing marketplace")
    end

    # Check that adding  the business was recorded in the
    # activity log for the investigation.
    click_link "Activity"
    expect(page).to have_text("Business added")
    expect_to_have_case_breadcrumbs

    expect(page.find("h3", text: "Business added"))
      .to have_sibling(".govuk-body", text: "Role: online_marketplace")
  end

  scenario "Not being able to add a business to another team's case" do
    sign_in other_user
    visit "/cases/#{investigation.pretty_id}/businesses"
    expect(page).not_to have_link("Add a business")
  end
end
