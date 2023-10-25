require "rails_helper"

RSpec.feature "Bulk upload products", :with_stubbed_mailer do
  let(:user) { create(:user, :opss_user, :activated, has_viewed_introduction: true, roles: %w[product_bulk_uploader]) }
  let(:online_marketplace) { create(:online_marketplace, name: "My marketplace", approved_by_opss: true) }

  before do
    online_marketplace

    sign_in(user)
  end

  scenario "Attempting to add unsafe products" do
    visit "/products/bulk-upload/triage"

    expect(page).to have_content("How would you describe the products in terms of their compliance and safety?")

    choose "Products are unsafe"
    click_button "Continue"

    expect(page).to have_content("You can’t upload multiple unsafe products")
  end

  scenario "Attempting to add a mix of unsafe and non-compliant products" do
    visit "/products/bulk-upload/triage"

    expect(page).to have_content("How would you describe the products in terms of their compliance and safety?")

    choose "Mix of non-compliant and unsafe products"
    click_button "Continue"

    expect(page).to have_content("You can’t upload a mix of multiple non-compliant and unsafe products")
  end

  scenario "Adding non-compliant products" do
    visit "/products/bulk-upload/triage"

    expect(page).to have_content("How would you describe the products in terms of their compliance and safety?")

    choose "Products are non-compliant"
    click_button "Continue"

    expect(page).to have_error_summary("Enter why the product is non-compliant")

    fill_in "Why is the product non-compliant?", with: "Testing"
    click_button "Continue"

    expect(page).to have_content("Create a case for multiple products")

    fill_in "Case name", with: "Test case"

    click_button "Continue"

    expect(page).to have_error_summary("Select yes if you want to add a reference number")

    choose "Yes"
    fill_in "Reference number", with: "1234"
    click_button "Continue"

    expect(page).to have_content("Add the business to the case")

    choose "Authorised representative"
    click_button "Continue"

    expect(page).to have_error_summary("Select whether the authorised representative is a UK or EU Authorised representative")

    choose "EU Authorised representative"
    click_button "Continue"

    expect(page).to have_content("Provide the business details")

    select "United Kingdom", from: "bulk_products_add_business_details_form_locations_attributes_0_country", match: :first
    click_button "Continue"
  end
end
