require "rails_helper"

RSpec.feature "Adding a product", :with_stubbed_mailer, :with_stubbed_elasticsearch, :with_product_form_helper do
  let(:user)          { create(:user, :activated) }
  let(:investigation) { create(:enquiry, creator: user) }
  let(:attributes)    { attributes_for(:product_iphone, authenticity: Product.authenticities.keys.without("missing").sample) }
  let(:other_user)    { create(:user, :activated) }

  before do
    ChangeCaseOwner.call!(investigation: investigation, owner: user.team, user: user)
  end

  scenario "Adding a product to a case" do
    sign_in user
    visit "/cases/#{investigation.pretty_id}/products/new"

    fill_in "Barcode number (GTIN, EAN or UPC)", with: "9781529034528"

    click_button "Save product"

    # Expected validation errors
    expect(page).to have_error_messages
    errors_list = page.find(".govuk-error-summary__list").all("li")
    expect(errors_list[0].text).to eq "Category cannot be blank"
    expect(errors_list[1].text).to eq "Subcategory type cannot be blank"
    expect(errors_list[2].text).to eq "You must state whether the product is a counterfeit"
    expect(errors_list[3].text).to eq "Name cannot be blank"
    expect(errors_list[4].text).to eq "Enter a valid barcode number"

    select attributes[:category], from: "Product category"

    fill_in "Product sub-category",                      with: attributes[:subcategory]
    fill_in "Product brand",                     with: attributes[:brand]
    fill_in "Product name",                      with: attributes[:name]
    fill_in "Barcode number (GTIN, EAN or UPC)", with: attributes[:gtin13]
    fill_in "Other product identifiers",         with: attributes[:product_code]
    fill_in "Batch number",                      with: attributes[:batch_number]
    fill_in "Webpage",                           with: attributes[:webpage]

    within_fieldset("Is the product counterfeit?") do
      choose counterfeit_answer(attributes[:authenticity])
    end

    select attributes[:country_of_origin], from: "Country of origin"

    fill_in "Description of product", with: attributes[:description]

    click_on "Save product"

    expect_to_be_on_investigation_products_page(case_id: investigation.pretty_id)
    expect(page).not_to have_error_messages

    expect(page).to have_summary_item(key: "Product brand",             value: attributes[:brand])
    expect(page).to have_summary_item(key: "Product name",              value: attributes[:name])
    expect(page).to have_summary_item(key: "Category",                  value: attributes[:category])
    expect(page).to have_summary_item(key: "Product sub-category",              value: attributes[:subcategory])
    expect(page).to have_summary_item(key: "Product authenticity",      value: I18n.t(attributes[:authenticity], scope: Product.model_name.i18n_key))
    expect(page).to have_summary_item(key: "Barcode number",            value: attributes[:gin13])
    expect(page).to have_summary_item(key: "Other product identifiers", value: attributes[:product_code])
    expect(page).to have_summary_item(key: "Batch number",              value: attributes[:batch_number])
    expect(page).to have_summary_item(key: "Webpage",                   value: attributes[:webpage])
    expect(page).to have_summary_item(key: "Country of origin",         value: attributes[:country])
    expect(page).to have_summary_item(key: "Description",               value: attributes[:description])
  end

  scenario "Not being able to add a product to another team’s case" do
    sign_in other_user
    visit "/cases/#{investigation.pretty_id}/products"

    expect(page).not_to have_link("Add product")
  end
end
