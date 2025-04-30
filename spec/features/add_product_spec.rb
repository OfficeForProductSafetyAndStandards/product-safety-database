require "rails_helper"

RSpec.feature "Adding a product", :with_flipper, :with_product_form_helper, :with_stubbed_antivirus, :with_stubbed_mailer do
  let(:user)       { create(:user, :activated) }
  let(:attributes) do
    attributes_for(:product_iphone, authenticity: Product.authenticities.keys.without("missing", "unsure").sample)
  end

  let(:invalid_image_file) { Rails.root.join("spec/fixtures/files/email.txt") }
  let(:valid_image_file) { Rails.root.join("spec/fixtures/files/testImage.png") }

  before do
    sign_in user
    visit "/products/new"
  end

  scenario "Adding a product" do
    fill_in "Barcode number (GTIN, EAN or UPC)", with: "invalid"

    click_button "Save"

    # Expected validation errors
    expect(page).to have_error_messages
    errors_list = page.find(".govuk-error-summary__list").all("li")
    expect(errors_list[0].text).to eq "Enter a valid product category"
    expect(errors_list[1].text).to eq "Enter a valid product subcategory"
    expect(errors_list[2].text).to eq "You must state whether the product is a counterfeit"
    expect(errors_list[3].text).to eq "Select yes if the product has UKCA, UKNI or CE marking"
    expect(errors_list[4].text).to eq "Name cannot be blank"
    expect(errors_list[5].text).to eq "Select yes if the product was placed on the market before 1 January 2021"
    expect(errors_list[6].text).to eq "Enter a valid barcode number"
    expect(errors_list[7].text).to eq "Country of origin cannot be blank"

    select attributes[:category], from: "Product category"

    fill_in "Product subcategory", with: attributes[:subcategory]
    fill_in "Manufacturer's brand name", with: attributes[:brand]
    fill_in "Product name", with: attributes[:name]
    fill_in "Barcode number (GTIN, EAN or UPC)", with: attributes[:barcode]
    fill_in "Other product identifiers", with: attributes[:product_code]
    fill_in "Webpage", with: attributes[:webpage]

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

    select attributes[:country_of_origin], from: "Country of origin"

    fill_in "Description of product", with: attributes[:description]

    click_on "Save"

    expect(page).to have_current_path("/products")
    expect(page).not_to have_error_messages
    expect(page).to have_selector("h1", text: "Product record created")

    click_on "View the product record"

    expected_markings = case attributes[:has_markings]
                        when "markings_yes" then attributes[:markings].join(", ")
                        when "markings_no" then "None"
                        when "markings_unknown" then "Unknown"
                        end

    expected_counterfeit_value = case attributes[:authenticity]
                                 when "genuine" then "No - This product record is about a genuine product"
                                 when "counterfeit" then "Yes - This is a product record for a counterfeit product"
                                 end

    expect(page).to have_summary_item(key: "Brand name", value: attributes[:brand])
    expect(page).to have_summary_item(key: "Product name", value: attributes[:name])
    expect(page).to have_summary_item(key: "Category", value: attributes[:category])
    expect(page).to have_summary_item(key: "Subcategory", value: attributes[:subcategory])
    expect(page).to have_summary_item(key: "Counterfeit", value: expected_counterfeit_value)
    expect(page).to have_summary_item(key: "Product marking", value: expected_markings)
    expect(page).to have_summary_item(key: "Barcode", value: attributes[:gin13])
    expect(page).to have_summary_item(key: "Other product identifiers", value: attributes[:product_code])
    expect(page).to have_summary_item(key: "Webpage", value: attributes[:webpage])
    expect(page).to have_summary_item(key: "Country of origin", value: attributes[:country])
    expect(page).to have_summary_item(key: "Description", value: attributes[:description])
    expect(page).to have_summary_item(key: "Market date", value: I18n.t(attributes[:when_placed_on_market], scope: Product.model_name.i18n_key))
  end

  context "when using the new taxonomy" do
    before do
      enable_feature(:new_taxonomy)
      create(:product_subcategory, name: attributes[:subcategory], product_category: create(:product_category, name: attributes[:category]))
    end

    scenario "Adding a product using the new taxonomy" do
      fill_in "Barcode number (GTIN, EAN or UPC)", with: "invalid"

      click_button "Save"

      # Expected validation errors
      expect(page).to have_error_messages
      errors_list = page.find(".govuk-error-summary__list").all("li")
      expect(errors_list[0].text).to eq "You must state whether the product is a counterfeit"
      expect(errors_list[1].text).to eq "Select yes if the product has UKCA, UKNI or CE marking"
      expect(errors_list[2].text).to eq "Name cannot be blank"
      expect(errors_list[3].text).to eq "Select yes if the product was placed on the market before 1 January 2021"
      expect(errors_list[4].text).to eq "Enter a valid barcode number"
      expect(errors_list[5].text).to eq "Country of origin cannot be blank"
      expect(errors_list[6].text).to eq "Select the main category"

      select attributes[:category], from: "Main category"
      select attributes[:subcategory], from: "Sub-category"

      fill_in "Manufacturer's brand name", with: attributes[:brand]
      fill_in "Product name", with: attributes[:name]
      fill_in "Barcode number (GTIN, EAN or UPC)", with: attributes[:barcode]
      fill_in "Other product identifiers", with: attributes[:product_code]
      fill_in "Webpage", with: attributes[:webpage]

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

      select attributes[:country_of_origin], from: "Country of origin"

      fill_in "Description of product", with: attributes[:description]

      click_on "Save"

      expect(page).to have_current_path("/products")
      expect(page).not_to have_error_messages
      expect(page).to have_selector("h1", text: "Product record created")

      click_on "View the product record"

      expected_markings = case attributes[:has_markings]
                          when "markings_yes" then attributes[:markings].join(", ")
                          when "markings_no" then "None"
                          when "markings_unknown" then "Unknown"
                          end

      expected_counterfeit_value = case attributes[:authenticity]
                                   when "genuine" then "No - This product record is about a genuine product"
                                   when "counterfeit" then "Yes - This is a product record for a counterfeit product"
                                   end

      expect(page).to have_summary_item(key: "Brand name", value: attributes[:brand])
      expect(page).to have_summary_item(key: "Product name", value: attributes[:name])
      expect(page).to have_summary_item(key: "Category", value: attributes[:category])
      expect(page).to have_summary_item(key: "Subcategory", value: attributes[:subcategory])
      expect(page).to have_summary_item(key: "Counterfeit", value: expected_counterfeit_value)
      expect(page).to have_summary_item(key: "Product marking", value: expected_markings)
      expect(page).to have_summary_item(key: "Barcode", value: attributes[:gin13])
      expect(page).to have_summary_item(key: "Other product identifiers", value: attributes[:product_code])
      expect(page).to have_summary_item(key: "Webpage", value: attributes[:webpage])
      expect(page).to have_summary_item(key: "Country of origin", value: attributes[:country])
      expect(page).to have_summary_item(key: "Description", value: attributes[:description])
      expect(page).to have_summary_item(key: "Market date", value: I18n.t(attributes[:when_placed_on_market], scope: Product.model_name.i18n_key))
    end
  end

  scenario "Adding a product with blank origin, it asserts validations" do
    select attributes[:category], from: "Product category"
    fill_in "Product subcategory", with: attributes[:subcategory]
    fill_in "Manufacturer's brand name", with: attributes[:brand]
    fill_in "Product name", with: attributes[:name]
    fill_in "Barcode number (GTIN, EAN or UPC)", with: attributes[:barcode]
    fill_in "Other product identifiers", with: attributes[:product_code]
    fill_in "Webpage", with: attributes[:webpage]

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

    fill_in "Description of product", with: attributes[:description]
    click_on "Save"

    # Expected validation errors
    expect(page).to have_error_messages
    errors_list = page.find(".govuk-error-summary__list").all("li")
    expect(errors_list[0].text).to eq "Country of origin cannot be blank"

    select attributes[:country_of_origin], from: "Country of origin"

    click_on "Save"
    expect(page).to have_current_path("/products")
    expect(page).not_to have_error_messages
    expect(page).to have_selector("h1", text: "Product record created")

    click_on "View the product record"
    expect(page).to have_summary_item(key: "Country of origin", value: attributes[:country])
  end

  scenario "Adding a product with unknown origin" do
    select attributes[:category], from: "Product category"
    fill_in "Product subcategory", with: attributes[:subcategory]
    fill_in "Manufacturer's brand name", with: attributes[:brand]
    fill_in "Product name", with: attributes[:name]
    fill_in "Barcode number (GTIN, EAN or UPC)", with: attributes[:barcode]
    fill_in "Other product identifiers", with: attributes[:product_code]
    fill_in "Webpage", with: attributes[:webpage]

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

    select "Unknown", from: "Country of origin"

    fill_in "Description of product", with: attributes[:description]
    click_on "Save"

    expect(page).to have_current_path("/products")
    expect(page).not_to have_error_messages
    expect(page).to have_selector("h1", text: "Product record created")

    click_on "View the product record"
    expect(page).to have_summary_item(key: "Country of origin", value: "Unknown")
  end

  scenario "Adding a product with an image" do
    select attributes[:category], from: "Product category"
    fill_in "Product subcategory", with: attributes[:subcategory]
    fill_in "Manufacturer's brand name", with: attributes[:brand]
    fill_in "Product name", with: attributes[:name]
    fill_in "Barcode number (GTIN, EAN or UPC)", with: attributes[:barcode]
    fill_in "Other product identifiers", with: attributes[:product_code]
    fill_in "Webpage", with: attributes[:webpage]

    attach_file "product[image]", valid_image_file

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

    select "Unknown", from: "Country of origin"
    fill_in "Description of product", with: attributes[:description]
    click_on "Save"

    expect(page).to have_current_path("/products")
    expect(page).not_to have_error_messages
    expect(page).to have_selector("h1", text: "Product record created")
    click_on "View the product record"
    expect(page).to have_summary_item(key: "Country of origin", value: "Unknown")
  end

  scenario "Adding a product with an invalid image" do
    select attributes[:category], from: "Product category"
    fill_in "Product subcategory", with: attributes[:subcategory]
    fill_in "Manufacturer's brand name", with: attributes[:brand]
    fill_in "Product name", with: attributes[:name]
    fill_in "Barcode number (GTIN, EAN or UPC)", with: attributes[:barcode]
    fill_in "Other product identifiers", with: attributes[:product_code]
    fill_in "Webpage", with: attributes[:webpage]

    # attach invalid image type
    attach_file "product[image]", invalid_image_file

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

    select "Unknown", from: "Country of origin"

    fill_in "Description of product", with: attributes[:description]
    click_on "Save"

    # Expected validation errors
    expect(page).to have_error_messages
    errors_list = page.find(".govuk-error-summary__list").all("li")
    expect(errors_list[0].text).to eq "The selected file must be a GIF, JPEG, PNG, WEBP or HEIC/HEIF"
  end

  context "when a product taxonomy export file exists" do
    let(:product_taxonomy_import) { create(:product_taxonomy_import, :with_export_file, state: "completed") }

    before do
      product_taxonomy_import
    end

    context "with the feature flag on" do
      before do
        enable_feature(:new_taxonomy)
        visit "/products/new" # revisit the page after creating the import
      end

      it "links to the file" do
        expect(page).to have_link("Download a full list of main and sub-categories", href: Rails.application.routes.url_helpers.rails_storage_proxy_path(product_taxonomy_import.export_file, only_path: true))
        expect(page).to have_selector("#product-category-hint", text: "Updated #{Time.zone.now.strftime('%d %B %Y')}. Download a full list of main and sub-categories.Please ensure you are viewing the latest version of the full category list.Once you select the main category, you will be able to select a related sub-category.")
      end
    end

    context "with the feature flag off" do
      before do
        disable_feature(:new_taxonomy)
        visit "/products/new" # revisit the page after creating the import
      end

      it "does not link to the file" do
        expect(page).to have_selector("#product-category-hint", text: "Select a category from the drop down")
      end
    end
  end

  context "when a product taxonomy export file does not exist" do
    it "does not link to the file" do
      expect(page).to have_selector("#product-category-hint", text: "Select a category from the drop down")
    end
  end
end
