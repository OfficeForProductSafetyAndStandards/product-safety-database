require "rails_helper"

RSpec.feature "Editing a product", :with_stubbed_elasticsearch, :with_product_form_helper do
  let(:product_code)      { Faker::Barcode.issn }
  let(:webpage)           { Faker::Internet.url }
  let(:user)              { create(:user, :activated, has_viewed_introduction: true) }
  let(:brand)             { Faker::Appliance.brand }
  let(:country_of_origin) { "France" }
  let(:product) do
    create(:product,
           authenticity: Product.authenticities[:missing],
           brand: brand,
           product_code: product_code,
           webpage: webpage,
           country_of_origin: country_of_origin)
  end

  let(:new_name)              { Faker::Commerce.product_name }
  let(:new_brand)             { Faker::Hipster.word }
  let(:new_description)       { Faker::Hipster.sentence }
  let(:new_product_category)  { (Rails.application.config.product_constants["product_category"] - [product.category]).sample }
  let(:new_product_type)      { Faker::Hipster.word }
  let(:new_gtin13)            { Faker::Barcode.ean(13) }
  let(:new_authenticity)      { (Product.authenticities.keys - [product.authenticity]).sample }
  let(:new_batch_number)      { Faker::Number.number(digits: 10) }
  let(:new_product_code)      { Faker::Barcode.issn }
  let(:new_webpage)           { Faker::Internet.url }
  let(:new_country_of_origin) { "South Korea" }

  before { sign_in user }

  it "allows to edit a product" do
    visit "/products/#{product.id}/edit"

    expect(page).to have_select("Product category", selected: product.category)
    expect(page).to have_field("Product type", with: product.product_type)

    within_fieldset "Is the product counterfeit?" do
      expect(page).to have_checked_field("Not provided")
    end

    expect(page).to have_field("Product brand",            with: product.brand)
    expect(page).to have_field("Product name",             with: product.name)
    expect(page).to have_field("Barcode number",           with: product.gtin13)
    expect(page).to have_field("Batch number",             with: product.batch_number)
    expect(page).to have_field("Other product identifier", with: "\r\n" + product.product_code)
    expect(page).to have_field("Webpage",                  with: product.webpage)
    expect(page).to have_select("Country of origin",       selected: "France")
    expect(page).to have_field("Description of product",   with: "\r\n" + product.description)

    select new_product_category, from: "Product category"
    fill_in "Product type", with: new_product_type

    within_fieldset "Is the product counterfeit?" do
      choose counterfeit_answer(new_authenticity)
    end

    fill_in "Product brand",            with: new_brand
    fill_in "Product name",             with: new_name
    fill_in "Barcode number",           with: new_gtin13
    fill_in "Batch number",             with: new_batch_number
    fill_in "Other product identifier", with: new_product_code
    fill_in "Webpage",                  with: new_webpage
    select new_country_of_origin,       from: "Country of origin"
    fill_in "Description of product",   with: new_description

    click_on "Save product"

    expect(page).to have_summary_item(key: "Category",                  value: new_product_category)
    expect(page).to have_summary_item(key: "Product type",              value: new_product_type)
    expect(page).to have_summary_item(key: "Product authenticity",      value: I18n.t(new_authenticity, scope: Product.model_name.i18n_key))
    expect(page).to have_summary_item(key: "Product brand",             value: new_brand)
    expect(page).to have_summary_item(key: "Product name",              value: new_name)
    expect(page).to have_summary_item(key: "Barcode number",            value: new_gtin13)
    expect(page).to have_summary_item(key: "Batch number",              value: new_batch_number)
    expect(page).to have_summary_item(key: "Other product identifiers", value: new_product_code)
    expect(page).to have_summary_item(key: "Webpage",                   value: new_webpage)
    expect(page).to have_summary_item(key: "Country of origin",         value: new_country_of_origin)
    expect(page).to have_summary_item(key: "Description",               value: new_description)
  end
end
