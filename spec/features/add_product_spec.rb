require "rails_helper"

RSpec.feature "Adding a product", :with_stubbed_mailer, :with_stubbed_elasticsearch, :with_product_form_helper do
  let(:user)          { create(:user, :activated) }
  let(:investigation) { create(:enquiry, creator: user) }
  let(:attributes)    do
    attributes_for(:product_iphone, authenticity: Product.authenticities.keys.without("missing").sample,
                                    affected_units_status: Product.affected_units_statuses.keys.sample)
  end
  let(:other_user) { create(:user, :activated) }

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
    expect(errors_list[1].text).to eq "Subcategory cannot be blank"
    expect(errors_list[2].text).to eq "You must state whether the product is a counterfeit"
    expect(errors_list[3].text).to eq "Select yes if the product was placed on the market before 1 January 2021"
    expect(errors_list[4].text).to eq "Select yes if the product has UKCA, UKNI or CE marking"
    expect(errors_list[5].text).to eq "You must state how many units are affected"
    expect(errors_list[6].text).to eq "Name cannot be blank"
    expect(errors_list[7].text).to eq "Enter a valid barcode number"

    select attributes[:category], from: "Product category"

    fill_in "Product subcategory",               with: attributes[:subcategory]
    fill_in "Product brand",                     with: attributes[:brand]
    fill_in "Product name",                      with: attributes[:name]
    fill_in "Barcode number (GTIN, EAN or UPC)", with: attributes[:gtin13]
    fill_in "Other product identifiers",         with: attributes[:product_code]
    fill_in "Batch number",                      with: attributes[:batch_number]
    fill_in "Webpage",                           with: attributes[:webpage]

    within_fieldset("Was the product placed on the market before 1 January 2021?") do
      choose when_placed_on_market_answer(attributes[:when_placed_on_market])
    end

    within_fieldset("Is the product counterfeit?") do
      choose counterfeit_answer(attributes[:authenticity])
    end

    within_fieldset("Does the product have UKCA, UKNI, or CE marking?") do
      page.find("input[value='#{attributes[:has_markings]}']").choose
    end

    within_fieldset("Select product marking") do
      attributes[:markings].each { |marking| check(marking) } if attributes[:has_markings] == "markings_yes"
    end

    within_fieldset("How many units are affected?") do
      choose affected_units_status_answer(attributes[:affected_units_status])
      find("#exact_units").set(10) if attributes[:affected_units_status] == "exact"
      find("#approx_units").set(10) if attributes[:affected_units_status] == "approx"
    end

    select attributes[:country_of_origin], from: "Country of origin"

    fill_in "Description of product", with: attributes[:description]

    click_on "Save product"

    expect_to_be_on_investigation_products_page(case_id: investigation.pretty_id)
    expect(page).not_to have_error_messages

    expected_markings = case attributes[:has_markings]
                        when "markings_yes" then attributes[:markings].join(", ")
                        when "markings_no" then "None"
                        when "markings_unknown" then "Unknown"
                        end

    expect(page).to have_summary_item(key: "Product brand",             value: attributes[:brand])
    expect(page).to have_summary_item(key: "Product name",              value: attributes[:name])
    expect(page).to have_summary_item(key: "Category",                  value: attributes[:category])
    expect(page).to have_summary_item(key: "Product subcategory",       value: attributes[:subcategory])
    expect(page).to have_summary_item(key: "Product authenticity",      value: I18n.t(attributes[:authenticity], scope: Product.model_name.i18n_key))
    expect(page).to have_summary_item(key: "Product marking",           value: expected_markings)
    expect(page).to have_summary_item(key: "Barcode number",            value: attributes[:gin13])
    expect(page).to have_summary_item(key: "Other product identifiers", value: attributes[:product_code])
    expect(page).to have_summary_item(key: "Batch number",              value: attributes[:batch_number])
    expect(page).to have_summary_item(key: "Webpage",                   value: attributes[:webpage])
    expect(page).to have_summary_item(key: "Country of origin",         value: attributes[:country])
    expect(page).to have_summary_item(key: "Description",               value: attributes[:description])
    expect(page).to have_summary_item(key: "When placed on market",     value: I18n.t(attributes[:when_placed_on_market], scope: Product.model_name.i18n_key))
  end

  scenario "Not being able to add a product to another team’s case" do
    sign_in other_user
    visit "/cases/#{investigation.pretty_id}/products"

    expect(page).not_to have_link("Add product")
  end
end
