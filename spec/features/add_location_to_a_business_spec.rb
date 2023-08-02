require "rails_helper"

RSpec.feature "Add a location to a business", :with_stubbed_antivirus, :with_stubbed_mailer, type: :feature do
  let(:user)     { create(:user, :activated, has_viewed_introduction: true) }
  let(:business) { create(:business, trading_name: "Acme Ltd") }

  scenario "Adding a location" do
    sign_in user
    visit "/businesses/#{business.id}"

    expect_to_be_on_business_page(business_id: business.id, business_name: "Acme Ltd")

    click_link "Add location"
    expect_to_be_on_add_business_to_location_page(business_id: business.id)
    expect_to_have_business_breadcrumbs

    fill_in "Location name", with: "Headquarters"

    fill_in "Building and street line 1 of 2", with: "Unit 1"
    fill_in "Building and street line 2 of 2", with: "100 High Street"
    fill_in "Town or city", with: "New Town"
    fill_in "County", with: "Townshire"
    fill_in "Postcode", with: "AB1 2CDE"
    select "Germany", from: "Country"

    click_button "Save"

    expect_to_be_on_business_page(business_id: business.id, business_name: "Acme Ltd")

    expect(page).to have_text("Headquarters")
    expect(page).to have_text("Unit 1, 100 High Street, New Town, AB1 2CDE, Germany")
  end
end
