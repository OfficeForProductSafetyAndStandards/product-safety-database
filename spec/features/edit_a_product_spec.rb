require "rails_helper"

RSpec.feature "Editing a product", :with_opensearch, :with_stubbed_mailer, :with_product_form_helper, :with_stubbed_antivirus do
  let(:product_code)      { Faker::Barcode.issn }
  let(:webpage)           { Faker::Internet.url }
  let(:user)              { create(:user, :activated, has_viewed_introduction: true) }
  let(:other_user)        { create(:user, :activated, has_viewed_introduction: true) }
  let(:brand)             { Faker::Appliance.brand }
  let(:country_of_origin) { "France" }
  let(:investigation) { create(:allegation, creator: user) }
  let(:product) do
    create(:product,
           authenticity: nil,
           brand:,
           product_code:,
           webpage:,
           country_of_origin:,
           has_markings: "markings_yes",
           investigations: [investigation],
           owning_team: user.team)
  end

  let(:new_name)              { Faker::Commerce.product_name }
  let(:new_brand)             { Faker::Hipster.word }
  let(:new_description)       { Faker::Hipster.sentence }
  let(:new_product_category)  { (Rails.application.config.product_constants["product_category"] - [product.category]).sample }
  let(:new_subcategory) { Faker::Hipster.word }
  let(:new_barcode)           { Faker::Barcode.ean(13) }
  let(:new_authenticity)      { (Product.authenticities.keys - [product.authenticity]).sample }
  let(:new_has_markings)      { Product.has_markings.keys.sample }
  let(:new_markings)          { [Product::MARKINGS.sample] }
  let(:new_product_code)      { Faker::Barcode.issn }
  let(:new_webpage)           { Faker::Internet.url }
  let(:new_country_of_origin) { "South Korea" }
  let(:new_when_placed_on_market) { (Product.when_placed_on_markets.keys - [product.when_placed_on_market]).sample }

  context "when the user is not in the team which owns the product" do
    before { sign_in other_user }

    it "does not allow user to edit the product" do
      visit "/products/#{product.id}"
      expect(page).not_to have_link "Edit details"

      visit "/cases/#{investigation.pretty_id}/products"
      expect(page).not_to have_link "Change product details"
    end
  end

  context "when the user is in the team which owns the product" do
    before { sign_in user }

    it "allows the user to edit the product" do
      visit "/cases/#{investigation.pretty_id}/products"
      expect(page).not_to have_link "Change product details"

      visit "/products/#{product.id}"

      expect(page).to have_summary_item(key: "Product authenticity", value: "Not provided")

      expect(page).to have_link "Edit details"
      click_link "Edit details"

      expect(page).to have_select("Product category", selected: product.category)
      expect(page).to have_field("Product subcategory", with: product.subcategory)

      within_fieldset "Is the product counterfeit?" do
        expect(page).not_to have_checked_field("Yes")
        expect(page).not_to have_checked_field("No")
        expect(page).not_to have_checked_field("Unsure")
      end

      within_fieldset("Does the product have UKCA, UKNI, or CE marking?") do
        expect(page).to have_checked_field("Yes")
      end

      within_fieldset("Select product marking") do
        product.markings.each { |marking| expect(page).to have_checked_field(marking) }
      end

      expect(page).to have_field("Manufacturer's brand name", with: product.brand)
      expect(page).to have_field("Product name",              with: product.name)
      expect(page).to have_field("Barcode number",            with: product.barcode)
      expect(page).to have_field("Other product identifier",  with: product.product_code)
      expect(page).to have_field("Webpage",                   with: product.webpage)
      expect(page).to have_select("Country of origin",        selected: "France")
      expect(page).to have_field("Description of product",    with: product.description)

      click_on "Save product"

      expect(page).to have_error_messages
      expect(page).to have_error_summary "You must state whether the product is a counterfeit"

      select new_product_category, from: "Product category"
      fill_in "Product subcategory", with: new_subcategory

      within_fieldset "Was the product placed on the market before 1 January 2021?" do
        choose when_placed_on_market_answer(new_when_placed_on_market)
      end

      within_fieldset "Is the product counterfeit?" do
        choose counterfeit_answer(new_authenticity)
      end

      within_fieldset("Does the product have UKCA, UKNI, or CE marking?") do
        page.find("input[value='#{new_has_markings}']").choose
      end

      within_fieldset("Select product marking") do
        all("input[type=checkbox]").each(&:uncheck)
        new_markings.each { |marking| check(marking) } if new_has_markings == "markings_yes"
      end

      fill_in "Manufacturer's brand name", with: new_brand
      fill_in "Product name",             with: new_name
      fill_in "Barcode number",           with: new_barcode
      fill_in "Other product identifier", with: new_product_code
      fill_in "Webpage",                  with: new_webpage
      select new_country_of_origin,       from: "Country of origin"
      fill_in "Description of product",   with: new_description

      click_on "Save product"

      expect_to_be_on_product_page(product_id: product.id, product_name: new_name)

      expected_markings = case new_has_markings
                          when "markings_yes" then new_markings.join(", ")
                          when "markings_no" then "None"
                          when "markings_unknown" then "Unknown"
                          end

      expect(page).to have_summary_item(key: "Category",                  value: new_product_category)
      expect(page).to have_summary_item(key: "Product subcategory",       value: new_subcategory)
      expect(page).to have_summary_item(key: "Product authenticity",      value: I18n.t(new_authenticity, scope: Product.model_name.i18n_key))
      expect(page).to have_summary_item(key: "Product marking",           value: expected_markings)
      expect(page).to have_summary_item(key: "Manufacturer's brand name", value: new_brand)
      expect(page).to have_summary_item(key: "Product name",              value: new_name)
      expect(page).to have_summary_item(key: "Barcode number",            value: new_barcode)
      expect(page).to have_summary_item(key: "Other product identifiers", value: new_product_code)
      expect(page).to have_summary_item(key: "Webpage",                   value: new_webpage)
      expect(page).to have_summary_item(key: "Country of origin",         value: new_country_of_origin)
      expect(page).to have_summary_item(key: "Description",               value: new_description)

      within("header") { click_on "Cases" }

      click_on "All cases – Search"

      fill_in "Search", with: new_name
      # sleep in order to wait for the changes to be indexed
      sleep 1
      click_on "Apply"

      expect(page).to have_listed_case(investigation.pretty_id)
    end

    scenario "upload an document" do
      visit "/products/#{product.id}"

      click_on "Attachments"
      click_on "Add attachment"

      attach_file file_fixture("corrective_action.txt")
      click_on "Save attachment"

      document_title       = Faker::Hipster.word
      document_description = Faker::Hipster.sentence
      fill_in "Document title", with: document_title
      fill_in "Description",    with: document_description

      click_on "Save attachment"
      click_on "Attachments (1)"

      expect(page).to have_css("h2.govuk-heading-m", text: document_title)
      expect(page).to have_css("p", text: document_description)
    end
  end

  context "when the product is not owned by a team" do
    before do
      product.update! owning_team: nil
      sign_in user
    end

    it "allows the user to edit the product, and their team becomes the owner" do
      visit "/cases/#{investigation.pretty_id}/products"
      expect(page).to have_link "Change product details"

      visit "/products/#{product.id}"

      expect(page).to have_summary_item(key: "Product authenticity", value: "Not provided")

      expect(page).to have_link "Edit details"
      click_link "Edit details"

      expect(page).to have_select("Product category", selected: product.category)
      expect(page).to have_field("Product subcategory", with: product.subcategory)

      within_fieldset "Is the product counterfeit?" do
        expect(page).not_to have_checked_field("Yes")
        expect(page).not_to have_checked_field("No")
        expect(page).not_to have_checked_field("Unsure")
      end

      within_fieldset("Does the product have UKCA, UKNI, or CE marking?") do
        expect(page).to have_checked_field("Yes")
      end

      within_fieldset("Select product marking") do
        product.markings.each { |marking| expect(page).to have_checked_field(marking) }
      end

      expect(page).to have_field("Manufacturer's brand name", with: product.brand)
      expect(page).to have_field("Product name",              with: product.name)
      expect(page).to have_field("Barcode number",            with: product.barcode)
      expect(page).to have_field("Other product identifier",  with: product.product_code)
      expect(page).to have_field("Webpage",                   with: product.webpage)
      expect(page).to have_select("Country of origin",        selected: "France")
      expect(page).to have_field("Description of product",    with: product.description)

      click_on "Save product"

      expect(page).to have_error_messages
      expect(page).to have_error_summary "You must state whether the product is a counterfeit"

      select new_product_category, from: "Product category"
      fill_in "Product subcategory", with: new_subcategory

      within_fieldset "Was the product placed on the market before 1 January 2021?" do
        choose when_placed_on_market_answer(new_when_placed_on_market)
      end

      within_fieldset "Is the product counterfeit?" do
        choose counterfeit_answer(new_authenticity)
      end

      within_fieldset("Does the product have UKCA, UKNI, or CE marking?") do
        page.find("input[value='#{new_has_markings}']").choose
      end

      within_fieldset("Select product marking") do
        all("input[type=checkbox]").each(&:uncheck)
        new_markings.each { |marking| check(marking) } if new_has_markings == "markings_yes"
      end

      fill_in "Manufacturer's brand name", with: new_brand
      fill_in "Product name",              with: new_name
      fill_in "Barcode number",            with: new_barcode
      fill_in "Other product identifier",  with: new_product_code
      fill_in "Webpage",                   with: new_webpage
      select new_country_of_origin,        from: "Country of origin"
      fill_in "Description of product",    with: new_description

      click_on "Save product"

      expect_to_be_on_product_page(product_id: product.id, product_name: new_name)

      expect(product.reload.owning_team).to eq(user.team)

      expected_markings = case new_has_markings
                          when "markings_yes" then new_markings.join(", ")
                          when "markings_no" then "None"
                          when "markings_unknown" then "Unknown"
                          end

      expect(page).to have_summary_item(key: "Category", value: new_product_category)
      expect(page).to have_summary_item(key: "Product subcategory", value: new_subcategory)
      expect(page).to have_summary_item(key: "Product authenticity",      value: I18n.t(new_authenticity, scope: Product.model_name.i18n_key))
      expect(page).to have_summary_item(key: "Product marking",           value: expected_markings)
      expect(page).to have_summary_item(key: "Manufacturer's brand name", value: new_brand)
      expect(page).to have_summary_item(key: "Product name",              value: new_name)
      expect(page).to have_summary_item(key: "Barcode number",            value: new_barcode)
      expect(page).to have_summary_item(key: "Other product identifiers", value: new_product_code)
      expect(page).to have_summary_item(key: "Webpage",                   value: new_webpage)
      expect(page).to have_summary_item(key: "Country of origin",         value: new_country_of_origin)
      expect(page).to have_summary_item(key: "Description",               value: new_description)

      within("header") { click_on "Cases" }

      click_on "All cases – Search"

      fill_in "Search", with: new_name
      # sleep in order to wait for the changes to be indexed
      sleep 1
      click_on "Apply"

      expect(page).to have_listed_case(investigation.pretty_id)
    end
  end
end
