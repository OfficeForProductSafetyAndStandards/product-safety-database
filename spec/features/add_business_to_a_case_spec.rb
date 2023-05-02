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

  before do
    ChangeCaseOwner.call!(investigation:, owner: user.team, user:)
  end

  scenario "Adding a business" do
    sign_in user
    visit "/cases/#{investigation.pretty_id}/businesses"

    click_link "Add a business"

    # Don't select a business type
    click_on "Continue"

    expect_to_be_on_investigation_add_business_type_page
    expect(page).to have_error_messages("Please select a business type")

    expect(page).to have_unchecked_field("Retailer")
    expect(page).to have_unchecked_field("Online seller - via an online marketplace")
    expect(page).to have_unchecked_field("Manufacturer")
    expect(page).to have_unchecked_field("Exporter")
    expect(page).to have_unchecked_field("Importer")
    expect(page).to have_unchecked_field("Fulfillment house")
    expect(page).to have_unchecked_field("Distributor")

    choose "Exporter"
    click_on "Continue"

    expect_to_be_on_investigation_add_business_details_page

    click_on "Save business"
    expect(page).to have_error_summary("Trading name cannot be blank")

    within_fieldset "The business details" do
      fill_in "Registered or legal name", with: business_details
      fill_in "Company number",           with: company_number
    end

    within_fieldset "Address" do
      fill_in "Building and street line 1 of 2",    with: address_line_one
      fill_in "Building and street line 2 of 2",    with: address_line_two
      fill_in "Town or city",        with: city
      fill_in "Postcode",            with: postcode
      select country,                from: "Country"
    end

    within_fieldset "The business contact" do
      fill_in "Name",                          with: name
      fill_in "Email",                         with: email
      fill_in "Phone number",                  with: phone_number
      fill_in "Job title or role description", with: job_title
    end

    click_on "Save business"

    expect(page).to have_error_summary("Trading name cannot be blank")

    within_fieldset "The business details" do
      fill_in "Trading name", with: trading_name
    end

    click_on "Save business"

    expect_to_be_on_investigation_businesses_page
    expect(page).not_to have_error_messages

    expected_address = [address_line_one, address_line_two, city, postcode, country].join(", ")

    within("section##{trading_name.parameterize}") do
      expect(page.find("dt", text: "Trading name")).to have_sibling("dd", text: trading_name)
      expect(page.find("dt", text: "Legal name")).to have_sibling("dd", text: business_details)
      expect(page.find("dt", text: "Company number")).to have_sibling("dd", text: company_number)
      expect(page.find("dt", text: "Address")).to have_sibling("dd", text: expected_address)
      expect(page.find("dt", text: "Position")).to have_sibling("dd", text: job_title)
      expect(page.find("dt", text: "Name")).to have_sibling("dd", text: name)
      expect(page.find("dt", text: "Telephone")).to have_sibling("dd", text: phone_number)
      expect(page.find("dt", text: "Email")).to have_sibling("dd", text: email)
    end

    # Check that adding  the business was recorded in the
    # activity log for the investigation.
    click_link "Activity"
    expect(page).to have_text("Business added")

    expect(page.find("h3", text: "Business added"))
      .to have_sibling(".govuk-body", text: "Role: exporter")

    expect(page)
      .to have_link("View business", href: /\/businesses\/(\d)+/)
  end

  scenario "Not being able to add a business to another team's case" do
    sign_in other_user
    visit "/cases/#{investigation.pretty_id}/businesses"
    expect(page).not_to have_link("Add a business")
  end
end
