require "rails_helper"

RSpec.feature "Adding a business", :with_stubbed_mailer, :with_stubbed_elasticsearch do
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
  let(:investigation)    { create(:enquiry) }

  before { sign_in }

  scenario "Adding a business" do
    visit "/cases/#{investigation.pretty_id}/businesses/new"

    choose "Manufacturer"
    click_on "Continue"

    within_fieldset "Business details" do
      fill_in "Trading name",             with: trading_name
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

    within_fieldset "Contact" do
      fill_in "Name",                          with: name
      fill_in "Email",                         with: email
      fill_in "Phone number",                  with: phone_number
      fill_in "Job title or role description", with: job_title
    end

    click_on "Save business"

    expect_to_be_on_investigation_businesses_page

    expect(page).to have_css("dt.govuk-summary-list__key",   text: "Trading name")
    expect(page).to have_css("dd.govuk-summary-list__value", text: trading_name)
    expect(page).to have_css("dt.govuk-summary-list__key",   text: "Registered or legal name")
    expect(page).to have_css("dd.govuk-summary-list__value", text: business_details)
    expect(page).to have_css("dt.govuk-summary-list__key",   text: "Company number")
    expect(page).to have_css("dd.govuk-summary-list__value", text: company_number)

    expected_address = [address_line_one, address_line_two, city, postcode, country].join(", ")
    expect(page).to have_css("dt.govuk-summary-list__key",   text: "Address")
    expect(page).to have_css("dd.govuk-summary-list__value", text: expected_address)

    expected_contact = [name, job_title, phone_number, email].join(", ")
    expect(page).to have_css("dt.govuk-summary-list__key",   text: "Contact")
    expect(page).to have_css("dd.govuk-summary-list__value", text: expected_contact)
  end

  def expect_to_be_on_investigation_businesses_page
    expect(page).to have_current_path("/cases/#{investigation.pretty_id}/businesses")
    expect(page).to have_selector("h1", text: "Businesses")
    expect(page).not_to have_error_messages
  end
end
