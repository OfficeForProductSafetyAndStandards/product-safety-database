require "rails_helper"

RSpec.feature "Duplicate Form Test", :with_product_form_helper, :with_stubbed_antivirus, :with_stubbed_mailer do
  let(:user)       { create(:user, :activated) }
  let(:attributes) do
    attributes_for(:product_iphone, authenticity: Product.authenticities.keys.without("missing", "unsure").sample)
  end
  let(:product) do
    create(:product_iphone,
           authenticity: "counterfeit",
           has_markings: "markings_yes",
           owning_team: user.team)
  end
  let(:attributes1) do
    attributes_for(:product_washing_machine, authenticity: Product.authenticities.keys.without("missing", "unsure").sample)
  end

  let(:invalid_image_file) { Rails.root.join("spec/fixtures/files/email.txt") }
  let(:valid_image_file) { Rails.root.join("spec/fixtures/files/testImage.png") }

  before do
    sign_in user
    product
    visit "/products"
  end

  scenario "Adding a duplicate product" do
    click_link "Create a product record"

    click_button "Continue"

    expect(page).to have_error_messages

    within_fieldset("Do you have the product barcode number?") do
      choose "Yes"
      fill_in "Barcode number", with: attributes[:barcode]
    end

    click_button "Continue"

    click_button "Continue"

    expect(page).to have_error_messages

    within_fieldset("Correct") do
      choose "Yes"
    end

    click_button "Continue"

    expect_to_be_on_product_page(product_id: Product.last.id, product_name: attributes[:name])
  end

  scenario "Adding a product with same barcode as an existing product" do
    click_link "Create a product record"

    click_button "Continue"

    expect(page).to have_error_messages

    within_fieldset("Do you have the product barcode number?") do
      choose "Yes"
      fill_in "Barcode number", with: attributes[:barcode]
    end
    click_button "Continue"

    click_button "Continue"

    expect(page).to have_error_messages

    within_fieldset("Correct") do
      choose "No"
    end
    click_button "Continue"

    click_on "Save"

    expect(page).to have_error_messages
    select attributes1[:category], from: "Product category"
    fill_in "Product subcategory", with: attributes1[:subcategory]
    fill_in "Manufacturer's brand name", with: attributes1[:brand]
    fill_in "Product name", with: attributes1[:name]
    fill_in "Barcode number (GTIN, EAN or UPC)", with: attributes1[:barcode]
    fill_in "Other product identifiers", with: attributes1[:product_code]
    fill_in "Webpage", with: attributes1[:webpage]

    within_fieldset("Was the product placed on the market before 1 January 2021?") do
      choose when_placed_on_market_answer(attributes1[:when_placed_on_market])
    end

    within_fieldset("Is the product counterfeit?") do
      choose counterfeit_answer(attributes1[:authenticity])
    end

    within_fieldset("Does the product have UKCA, UKNI, or CE marking?") do
      page.find("input[value='#{attributes1[:has_markings]}']").choose
    end

    within_fieldset("Select product marking") do
      attributes1[:markings].each { |marking| check(marking) } if attributes1[:has_markings] == "markings_yes"
    end

    select attributes1[:country_of_origin][0], from: "Country of origin"

    fill_in "Description of product", with: attributes1[:description]
    click_on "Save"

    expect(page).to have_current_path("/products")
    expect(page).not_to have_error_messages
    expect(page).to have_selector("h1", text: "Product record created")

    click_on "View the product record"
    expect(page).to have_summary_item(key: "Category", value: attributes1[:category])
    expect(page).to have_summary_item(key: "Subcategory", value: attributes1[:subcategory])
    if attributes1[:authenticity] == "counterfeit"
      expect(page).to have_summary_item(key: "Counterfeit", value: "Yes - This is a product record for a counterfeit product")
    elsif attributes1[:authenticity] == "genuine"
      expect(page).to have_summary_item(key: "Counterfeit", value: "No - This product record is about a genuine product")
    else
      expect(page).to have_summary_item(key: "Counterfeit", value: "Unsure")
    end

    if attributes1[:has_markings] == "markings_unknown"
      expect(page).to have_summary_item(key: "Product marking", value: "Unknown")
    elsif attributes1[:has_markings] == "markings_no"
      expect(page).to have_summary_item(key: "Product marking", value: "None")
    elsif attributes1[:markings].length >= 2
      expect(page).to have_summary_item(key: "Product marking", value: attributes1[:markings].join(", "))
    else
      expect(page).to have_summary_item(key: "Product marking", value: attributes1[:markings].join(""))
    end

    expect(page).to have_summary_item(key: "Brand name", value: attributes1[:brand])
    expect(page).to have_summary_item(key: "Product name", value: attributes1[:name])
    expect(page).to have_summary_item(key: "Barcode", value: attributes1[:barcode])
    expect(page).to have_summary_item(key: "Other product identifiers", value: attributes1[:product_code])
    expect(page).to have_summary_item(key: "Webpage", value: attributes1[:webpage])
    expect(page).to have_summary_item(key: "Country of origin", value: attributes1[:country_of_origin][0])
    expect(page).to have_summary_item(key: "Description", value: attributes1[:description])
  end
end
