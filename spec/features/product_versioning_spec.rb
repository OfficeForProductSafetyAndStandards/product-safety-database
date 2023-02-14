require "rails_helper"

RSpec.feature "Product versioning", :with_opensearch, :with_stubbed_mailer, type: :feature do
  let(:user) { create :user, :activated, has_viewed_introduction: true }
  let(:initial_product_description) { "Widget" }
  let(:new_product_description) { "Sausage" }
  let(:creation_time) { 1.day.ago }
  let(:product) { create(:product, description: initial_product_description) }
  let(:investigation) { create(:allegation, creator: user, products: [product]) }

  before do
    sign_in(user)

    travel_to(creation_time) { product }

    visit product_path(product)
  end

  scenario "editing a product" do
    expect_to_be_on_product_page(product_id: product.id, product_name: product.name)
    expect(page).to have_summary_item(key: "PSD ref", value: "psd-#{product.id} - The PSD reference number for this product record")
    expect(page).to have_summary_item(key: "Description", value: initial_product_description)

    # Close the case which has the product attatched, to create a "timestamped" version
    visit "/cases/#{investigation.pretty_id}"
    click_link "Close this case"
    fill_in "Why are you closing the case?", with: "Case has been resolved."
    click_button "Close case"
    expect_confirmation_banner("Allegation was closed")
    investigation.reload

    visit product_path(product)
    click_link "Edit the product record"

    fill_in "Description of product", with: new_product_description
    click_button "Save"

    # Ensure product page shows latest version
    expect_to_be_on_product_page(product_id: product.id, product_name: product.name)
    expect(page).to have_summary_item(key: "PSD ref", value: "psd-#{product.id} - The PSD reference number for this product record")
    expect(page).to have_summary_item(key: "Description", value: new_product_description)

    # Old version should be accessible
    visit "/cases/#{investigation.pretty_id}/products"

    expect(page).to have_selector("h3.govuk-heading-m", text: product.name)
    expect(page).to have_selector("dd.govuk-summary-list__value", text: "psd-#{product.id}_#{investigation.date_closed.to_i} - The PSD reference for this version of the product record - as recorded when the case was closed: #{investigation.date_closed.to_fs(:govuk)}.")
    expect(page).to have_selector("dd.govuk-summary-list__value", text: initial_product_description)
    expect(page).not_to have_link "Edit this product"

    # Search should only index current version
    Product.import refresh: :wait_for

    visit all_products_path

    expect(page).to have_selector("h1", text: "All products – Search")

    fill_in "Search", with: new_product_description
    click_button "Submit search"

    expect(page).to have_text(product.name)

    fill_in "Search", with: initial_product_description
    click_button "Submit search"

    expect(page).not_to have_text(product.name)
  end
end
