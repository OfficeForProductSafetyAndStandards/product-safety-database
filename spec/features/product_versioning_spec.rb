require "rails_helper"

RSpec.feature "Product versioning", :with_opensearch, :with_stubbed_mailer, type: :feature do
  let(:user) { create(:user, :activated) }
  let(:initial_product_description) { "Widget" }
  let(:new_product_description) { "Sausage" }
  let(:creation_time) { 1.day.ago }
  let(:product) { create(:product, description: initial_product_description) }

  before do
    sign_in(user)

    travel_to(creation_time) { product }

    visit product_path(product)
  end

  scenario "editing a product" do
    expect_to_be_on_product_page(product_id: product.id, product_name: product.name)
    expect(page).to have_summary_item(key: "PSD ref", value: "psd-#{product.id} - The PSD reference for this product record")
    expect(page).to have_summary_item(key: "Description", value: initial_product_description)

    click_link "Edit details"

    fill_in "Description of product", with: new_product_description
    click_button "Save"

    # Ensure product page shows latest version
    expect_to_be_on_product_page(product_id: product.id, product_name: product.name)
    expect(page).to have_summary_item(key: "PSD ref", value: "psd-#{product.id} - The PSD reference for this product record")
    expect(page).to have_summary_item(key: "Description", value: new_product_description)

    # Old version should be accessible
    visit product_version_path(product, timestamp: creation_time.to_i)

    expect(page).to have_selector("h1", text: product.name)
    expect(page).to have_summary_item(key: "PSD ref", value: "psd-#{product.id}_#{creation_time.to_i} - The PSD reference for this product record")
    expect(page).to have_summary_item(key: "Description", value: initial_product_description)
    expect(page).not_to have_link "Edit details"

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
