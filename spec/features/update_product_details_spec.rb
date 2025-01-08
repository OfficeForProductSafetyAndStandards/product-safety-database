require "rails_helper"

RSpec.feature "Updating product details", :with_stubbed_mailer, type: :feature do
  let(:user) { create(:user, :activated) }

  let(:product) do
    create(:product,
           brand: "MyBrand",
           name: "Washing machine",
           category: "Electrical appliances and equipment",
           country_of_origin: "country:AL",
           subcategory: "washing machine",
           product_code: "MBWM01",
           webpage: "http://example.com/mybrand/washing-machines",
           description: "White with chrome buttons",
           owning_team: user.team)
  end

  scenario "Updating a product" do
    sign_in(user)

    visit "/products/#{product.id}"
    expect_to_be_on_product_page(product_id: product.id, product_name: "Washing machine")

    click_link "Edit this product record"

    expect_to_be_on_edit_product_page(product_id: product.id, product_name: "Washing machine")

    expect(page).to have_field("Product category", with: "Electrical appliances and equipment")
    expect(page).to have_field("Product subcategory", with: "washing machine")
    expect(page).to have_field("Manufacturer's brand name", with: "MyBrand", disabled: true)
    expect(page).to have_field("Product name", with: "Washing machine", disabled: true)
    expect(page).to have_field("Other product identifiers", text: "MBWM01")
    expect(page).to have_field("Webpage", with: "http://example.com/mybrand/washing-machines")
    expect(page).to have_field("Description of product", text: "White with chrome buttons")

    fill_in "Product subcategory", with: "dishwasher"
    fill_in "Other product identifiers", with: "MBDW01"
    fill_in "Webpage", with: "http://example.com/mybrand/dishwashers"
    fill_in "Description of product", with: "White with chrome handle"

    click_button "Save"

    expect_to_be_on_product_page(product_id: product.id, product_name: "Washing machine")

    expect(page).to have_text "The product record was updated"

    expect(page).to have_summary_item(key: "PSD ref", value: "#{product.psd_ref} - The PSD reference number for this product record")
    expect(page).to have_summary_item(key: "Brand name", value: "MyBrand")
    expect(page).to have_summary_item(key: "Product name", value: "Washing machine")
    expect(page).to have_summary_item(key: "Category", value: "Electrical appliances and equipment")
    expect(page).to have_summary_item(key: "Subcategory", value: "dishwasher")
    expect(page).to have_summary_item(key: "Other product identifiers", value: "MBDW01")
    expect(page).to have_summary_item(key: "Webpage", value: "http://example.com/mybrand/dishwashers")
    expect(page).to have_summary_item(key: "Description", value: "White with chrome handle")
  end
end
