require "rails_helper"

RSpec.feature "Adding and removing business to a case", :with_stubbed_mailer, :with_stubbed_elasticsearch do
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
  let(:investigation)    { create(:enquiry, owner: user.team) }
  let!(:another_user_another_team) { create(:user, :activated, email: "active.otherteam@example.com", organisation: user.organisation, team: create(:team)) }

  scenario "when user from another team,it doesn't allow to add business" do
    sign_in another_user_another_team
    visit "/cases/#{investigation.pretty_id}/businesses"
    page.should have_no_content("Add business")
  end

  scenario "Adding a business" do
    sign_in user
    visit "/cases/#{investigation.pretty_id}/businesses/new"

    # Don't select a business type
    click_on "Continue"

    expect_to_be_on_investigation_add_business_type_page

    expect(page).to have_text("Please select a business type")

    choose "Other"
    click_on "Continue"

    expect_to_be_on_investigation_add_business_type_page

    expect(page).to have_text('Please enter a business type "Other"')

    choose "Other" # This shouldn't need to be re-selected, but currently does.
    fill_in "Other type", with: "Advertiser"

    click_on "Continue"

    expect_to_be_on_investigation_add_business_details_page

    within_fieldset "Business details" do
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

    expect(page).to have_text("Trading name cannot be blank")

    within_fieldset "Business details" do
      fill_in "Trading name", with: trading_name
    end

    click_on "Save business"

    expect_to_be_on_investigation_businesses_page
    expect(page).not_to have_error_messages

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

    # edit business details
    click_link "View business"
    click_link "Edit details"

    expect_to_be_on_investigation_edit_business_details_page

    within_fieldset "Business details" do
      fill_in "Registered or legal name", with: business_details + "edit details"
      fill_in "Company number",           with: company_number   + "906"
    end

    click_button "Save business"
    expect_confirmation_banner("Business was successfully updated.")
    expect(page).to have_css("dd.govuk-summary-list__value", text: business_details + "edit details")
    expect(page).to have_css("dd.govuk-summary-list__value", text: company_number   + "906")

    visit "/cases/#{investigation.pretty_id}/businesses"
    click_link "Remove business"

    expect_to_be_on_remove_business_page
    click_button "Remove business"
    expect_confirmation_banner("Business was successfully removed.")
  end
end
