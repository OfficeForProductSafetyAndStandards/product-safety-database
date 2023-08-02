require "rails_helper"

RSpec.feature "Editing a business location", :with_stubbed_antivirus, :with_stubbed_mailer, type: :feature do
  let(:user)     { create(:user, :activated, has_viewed_introduction: true) }
  let(:business) { create(:business, trading_name: "Acme Ltd") }
  let!(:location) do
    create(:location,
           business:,
           name: "Headquarters",
           address_line_1: "Unit 1",
           address_line_2: "100 High Street",
           city: "New Town",
           county: "Townshire",
           postal_code: "AB1 2CDE",
           country: "country:GB")
  end

  scenario "Editing a location" do
    sign_in user

    visit "/businesses/#{business.id}"

    expect_to_be_on_business_page(business_id: business.id, business_name: "Acme Ltd")

    click_link "Edit location"

    expect_to_be_on_edit_location_for_a_business_page(business_id: business.id, location_id: location.id)
    expect_to_have_business_breadcrumbs

    # Expect fields to be prefilled
    expect(page).to have_field("Location name", with: "Headquarters")
    expect(page).to have_field("Building and street line 1 of 2", with: "Unit 1")
    expect(page).to have_field("Building and street line 2 of 2", with: "100 High Street")
    expect(page).to have_field("Town or city", with: "New Town")
    expect(page).to have_field("County", with: "Townshire")
    expect(page).to have_field("Postcode", with: "AB1 2CDE")

    # Change all the values
    fill_in "Location name", with: "Registered office"
    fill_in "Building and street line 1 of 2", with: "Unit 100"
    fill_in "Building and street line 2 of 2", with: "99 High Road"
    fill_in "Town or city", with: "Old Town"
    fill_in "County", with: "Countryshire"
    fill_in "Postcode", with: "ZZ1 2YX"
    select "France", from: "Country"

    click_button "Save"

    expect_to_be_on_business_page(business_id: business.id, business_name: "Acme Ltd")

    expect(page).to have_text("Registered office")
    expect(page).to have_text("Unit 100, 99 High Road, Old Town, ZZ1 2YX, France")
  end
end
