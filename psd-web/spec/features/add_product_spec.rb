require "rails_helper"

RSpec.feature "Adding a product", :with_stubbed_mailer, :with_stubbed_elasticsearch do
  let(:investigation) { create(:enquiry) }
  let(:product)       { create(:product_iphone) }

  before { sign_in }

  scenario "Adding a product to a case" do
    visit "/cases/#{investigation.pretty_id}/products/new"

    select product.category, from: "Product category"

    fill_in "Product type", with: product.product_type
    fill_in "Product name", with: product.name
    fill_in "Barcode or serial number", with: product.product_code
    fill_in "Batch number", with: product.batch_number
    fill_in "Webpage", with: product.webpage

    select product.country_of_origin, from: "Country of origin"

    fill_in "Description of product", with: product.description

    click_on "Save product"

    expect_to_be_on_investigation_products_page

    expect(page).to have_css("dt.govuk-summary-list__key",   text: "Product name")
    expect(page).to have_css("dd.govuk-summary-list__value", text: product.name)
    expect(page).to have_css("dt.govuk-summary-list__key",   text: "Category")
    expect(page).to have_css("dd.govuk-summary-list__value", text: product.category)
    expect(page).to have_css("dt.govuk-summary-list__key",   text: "Product type")
    expect(page).to have_css("dd.govuk-summary-list__value", text: product.product_type)
    expect(page).to have_css("dt.govuk-summary-list__key",   text: "Barcode or serial number")
    expect(page).to have_css("dd.govuk-summary-list__value", text: product.product_code)
    expect(page).to have_css("dt.govuk-summary-list__key",   text: "Batch number")
    expect(page).to have_css("dd.govuk-summary-list__value", text: product.batch_number)
    expect(page).to have_css("dt.govuk-summary-list__key",   text: "Webpage")
    expect(page).to have_css("dd.govuk-summary-list__value", text: product.webpage)
    expect(page).to have_css("dt.govuk-summary-list__key",   text: "Country of origin")
    expect(page).to have_css("dd.govuk-summary-list__value", text: product.country_of_origin)
    expect(page).to have_css("dt.govuk-summary-list__key",   text: "Description")
    expect(page).to have_css("dd.govuk-summary-list__value", text: product.description)
  end

  def expect_to_be_on_investigation_products_page
    expect(page).to have_current_path("/cases/#{investigation.pretty_id}/products")
    expect(page).to have_selector("h1", text: "Products")
    expect(page).not_to have_error_messages
  end
end
