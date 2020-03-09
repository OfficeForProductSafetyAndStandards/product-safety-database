require "rails_helper"

RSpec.feature "Adding a business", :with_stubbed_mailer, :with_stubbed_elasticsearch, :with_stubbed_keycloak_config do
  let(:city)          { Faker::Space.planet }
  let(:trading_name)  { Faker::Company.name }
  let(:investigation) { create(:enquiry) }

  before { sign_in }

  it "allows the relevent params to be posted" do
    visit "/cases/#{investigation.pretty_id}/businesses/new"

    choose "Manufacturer"
    click_on "Continue"

    fill_in "Trading name", with: trading_name
    fill_in "Town or city", with: city
    click_on "Save business"

    click_on "Businesses (#{investigation.businesses.count})"

    expect(page).to have_css("dt.govuk-summary-list__key", text: "Address")
    expect(page).to have_css("dd.govuk-summary-list__value", text: city)
  end
end
