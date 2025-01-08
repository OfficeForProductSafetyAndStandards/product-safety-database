require "rails_helper"

RSpec.feature "Deleting a business location", :with_stubbed_antivirus, :with_stubbed_mailer, type: :feature do
  let(:user)     { create(:user, :activated, has_viewed_introduction: true) }
  let(:business) { create(:business, trading_name: "Acme Ltd") }
  let!(:location) do
    create(:location,
           business:,
           name: "Headquarters",
           address_line_1: "Unit 1",
           postal_code: "ABC 123",
           phone_number: "01632 960 001")
  end

  scenario "Editing a location" do
    sign_in user

    visit "/businesses/#{business.id}"

    expect_to_be_on_business_page(business_id: business.id, business_name: "Acme Ltd")

    click_link "Remove location"

    expect_to_be_on_remove_location_for_a_business_page(business_id: business.id, location_id: location.id)
    expect(page).to have_text("Headquarters")
    expect(page).to have_text("Unit 1")
    expect(page).to have_text("ABC 123")
    expect(page).to have_text("01632 960 001")
    expect_to_have_business_breadcrumbs

    click_button "Remove location"

    expect_to_be_on_business_page(business_id: business.id, business_name: "Acme Ltd")
    expect(page).not_to have_text("Headquarters")
    expect(page).to have_text("No locations")
  end
end
