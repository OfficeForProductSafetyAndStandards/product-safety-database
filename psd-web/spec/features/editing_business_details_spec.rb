require "rails_helper"

RSpec.feature "Editing business details", :with_stubbed_mailer, :with_stubbed_elasticsearch do
  let(:user)      { create(:user, :activated) }
  let(:business)  { create(:business, trading_name: "OldCo") }

  before do
    create(:contact, business: business)
  end

  scenario "Updating a business’s details" do
    sign_in user
    visit "/businesses/#{business.id}"

    expect_to_be_on_business_page(business_id: business.id, business_name: "OldCo")

    click_link "Edit details"

    expect_to_be_on_edit_business_page(business_id: business.id, business_name: "OldCo")

    within_fieldset "Business details" do
      fill_in "Trading name", with: "NewCo"
      fill_in "Registered or legal name", with: "NewCo Ltd"
      fill_in "Company number", with: "222 222 22"
    end

    within_fieldset "Address" do
      fill_in "Building and street line 1 of 2", with: "22 New Street"
      fill_in "Building and street line 2 of 2", with: "New Town"
      fill_in "Town or city", with: "Newcity"
      fill_in "County", with: "Newchester"
      fill_in "Postcode", with: "NE2 2EW"
    end

    within_fieldset "Contact" do
      fill_in "Name", with: "Mr New"
      fill_in "Email", with: "contact@newco.example"
      fill_in "Phone number", with: "01632 960000"
      fill_in "Job title or role description", with: "CEO"
    end

    click_button "Save business"

    expect_to_be_on_business_page(business_id: business.id, business_name: "NewCo")
    expect_confirmation_banner("Business was successfully updated.")

    expect(page).to have_summary_item(key: "Trading name", value: "NewCo")
    expect(page).to have_summary_item(key: "Registered or legal name", value: "NewCo Ltd")
    expect(page).to have_summary_item(key: "Company number", value: "222 222 22")

    expect(page).to have_summary_item(key: "Address", value: "22 New Street, New Town, Newcity, NE2 2EW")

    expect(page).to have_summary_item(key: "Contact", value: "Mr New, CEO, 01632 960000, contact@newco.example")
  end
end
