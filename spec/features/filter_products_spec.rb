require "rails_helper"

RSpec.feature "Product filtering", :with_opensearch, :with_stubbed_mailer, type: :feature do
  let(:organisation)          { create(:organisation) }
  let(:user)                  { create(:user, :activated, organisation:, has_viewed_introduction: true) }
  let(:opss_user)             { create(:user, :opss_user, :activated, organisation:, has_viewed_introduction: true) }

  let!(:chemical_investigation)              { create(:notification, hazard_type: "Chemical") }
  let!(:fire_investigation)                  { create(:notification, hazard_type: "Fire") }
  let!(:drowning_investigation)              { create(:notification, hazard_type: "Drowning") }
  let!(:allegation) { create(:allegation, hazard_type: "Drowning") }

  let!(:lift_product_1)   { create(:product, name: "Elevator", investigations: [fire_investigation], category: "Clothing, textiles and fashion items", country_of_origin: "territory:AE-AZ") }
  let!(:lift_product_2)   { create(:product, name: "Very hot product", investigations: [fire_investigation], category: "Clothing, textiles and fashion items") }
  let!(:furniture_product) { create(:product, name: "Hot product1", investigations: [chemical_investigation], category: "Furniture") }
  let!(:sanitiser_product) { create(:product, name: "SoapForHandz", investigations: [drowning_investigation], category: "Communication and media equipment") }
  let!(:retired_sanitiser_product) { create(:product, name: "Dangerous retired life vest", investigations: [drowning_investigation], retired_at: Time.zone.now, category: "Hand sanitiser") }
  let!(:allegation_product) { create(:product, name: "Allegation Product", investigations: [allegation], category: "Communication and media equipment") }

  before do
    Investigation.reindex
  end

  context "when user is non OPSS" do
    before do
      sign_in(user)
      visit products_path
    end

    scenario "no filters applied shows all non-retired products" do
      expect(page).to have_content(lift_product_1.name)
      expect(page).to have_content(lift_product_2.name)
      expect(page).to have_content(furniture_product.name)
      expect(page).to have_content(sanitiser_product.name)
      expect(page).not_to have_content(allegation_product.name)
      expect(page).to have_content("There are currently 4 products.")
    end

    context "when there are multiple pages of products" do
      before do
        17.times { Product.create(name: "TestProduct") }
        visit products_path
      end

      it "shows total number of products that the user has access to regardless of how many are on the current page" do
        expect(page).to have_content("There are currently #{Product.not_retired.joins(:investigations).where(investigations: { type: ['Investigation::Notification', nil] }).count} products.")
      end
    end

    scenario "filtering by category" do
      select "Clothing, textiles and fashion items", from: "Category"
      click_button "Apply"

      expect(page).to have_content(lift_product_1.name)
      expect(page).to have_content(lift_product_2.name)
      expect(page).not_to have_content(furniture_product.name)
      expect(page).not_to have_content(sanitiser_product.name)
      expect(page).not_to have_content(retired_sanitiser_product.name)
      expect(page).to have_content("2 products using the current filters, were found.")
    end

    scenario "filtering by category and a keyword" do
      select "Clothing, textiles and fashion items", from: "Category"
      fill_in "Search", with: "Elevator"
      click_button "Apply"

      expect(page).to have_content(lift_product_1.name)
      expect(page).not_to have_content(lift_product_2.name)
      expect(page).not_to have_content(furniture_product.name)
      expect(page).not_to have_content(sanitiser_product.name)
      expect(page).not_to have_content(retired_sanitiser_product.name)
      expect(page).to have_content("1 product matching keyword(s) Elevator, using the current filters, was found.")
    end

    scenario "filtering by a keyword" do
      fill_in "Search", with: "SoapForHandz"
      click_button "Apply"

      expect(page).not_to have_content(lift_product_1.name)
      expect(page).not_to have_content(lift_product_2.name)
      expect(page).not_to have_content(furniture_product.name)
      expect(page).to have_content(sanitiser_product.name)
      expect(page).not_to have_content(retired_sanitiser_product.name)
      expect(page).to have_content("1 product matching keyword(s) SoapForHandz, was found.")
    end

    scenario "filtering by a keyword with whitespaces" do
      fill_in "Search", with: "   SoapForHandz    "
      click_button "Apply"

      expect(page).not_to have_content(lift_product_1.name)
      expect(page).not_to have_content(lift_product_2.name)
      expect(page).not_to have_content(furniture_product.name)
      expect(page).to have_content(sanitiser_product.name)
      expect(page).not_to have_content(retired_sanitiser_product.name)
      expect(page).to have_content("1 product matching keyword(s) SoapForHandz, was found.")
    end

    scenario "filtering by an ID" do
      fill_in "Search", with: furniture_product.id
      click_button "Apply"

      expect(page).not_to have_content(lift_product_1.name)
      expect(page).not_to have_content(lift_product_2.name)
      expect(page).to have_content(furniture_product.name)
      expect(page).not_to have_content(sanitiser_product.name)
      expect(page).not_to have_content(retired_sanitiser_product.name)
    end

    scenario "filtering by a PSD ref" do
      fill_in "Search", with: lift_product_2.psd_ref
      click_button "Apply"

      expect(page).not_to have_content(lift_product_1.name)
      expect(page).to have_content(lift_product_2.name)
      expect(page).not_to have_content(furniture_product.name)
      expect(page).not_to have_content(sanitiser_product.name)
      expect(page).not_to have_content(retired_sanitiser_product.name)
    end
  end

  context "when user is OPSS" do
    before do
      sign_in(opss_user)
      visit products_path
    end

    scenario "no filters applied shows all non-retired products" do
      expect(page).to have_content(lift_product_1.name)
      expect(page).to have_content(lift_product_2.name)
      expect(page).to have_content(furniture_product.name)
      expect(page).to have_content(sanitiser_product.name)
      expect(page).not_to have_content(retired_sanitiser_product.name)
      expect(page).to have_content(allegation_product.name)
      expect(page).to have_content("There are currently 5 products.")
    end

    scenario "filtering by active products" do
      within_fieldset("Product record status") { choose "Active" }
      click_button "Apply"

      expect(page).to have_content(lift_product_1.name)
      expect(page).to have_content(lift_product_2.name)
      expect(page).to have_content(furniture_product.name)
      expect(page).to have_content(sanitiser_product.name)
      expect(page).not_to have_content(retired_sanitiser_product.name)
      expect(page).to have_content(allegation_product.name)
      expect(page).to have_content("5 products using the current filters, were found.")
    end

    scenario "filtering by retired products" do
      within_fieldset("Product record status") { choose "Retired" }
      click_button "Apply"

      expect(page).not_to have_content(lift_product_1.name)
      expect(page).not_to have_content(lift_product_2.name)
      expect(page).not_to have_content(furniture_product.name)
      expect(page).not_to have_content(sanitiser_product.name)
      expect(page).to have_content("#{retired_sanitiser_product.name} (Retired product record)")
      expect(page).not_to have_content(allegation_product.name)
      expect(page).to have_content("1 product using the current filters, was found.")
    end

    scenario "filtering by both retired and active products" do
      within_fieldset("Product record status") { choose "All" }
      click_button "Apply"

      expect(page).to have_content(lift_product_1.name)
      expect(page).to have_content(lift_product_2.name)
      expect(page).to have_content(furniture_product.name)
      expect(page).to have_content(sanitiser_product.name)
      expect(page).to have_content("#{retired_sanitiser_product.name} (Retired product record)")
      expect(page).to have_content(allegation_product.name)
      expect(page).to have_content("6 products using the current filters, were found.")
    end

    scenario "filtering by country" do
      find("details#products-countries").click
      check "Abu Dhabi"
      click_button "Apply"

      expect(page).to have_content(lift_product_1.name)
      expect(page).not_to have_content(lift_product_2.name)
      expect(page).not_to have_content(furniture_product.name)
      expect(page).not_to have_content(sanitiser_product.name)
      expect(page).not_to have_content("#{retired_sanitiser_product.name} (Retired product record)")
      expect(page).not_to have_content(allegation_product.name)
      expect(page).to have_content("1 product using the current filters, was found.")
    end

    scenario "filtering by notification type" do
      find("details#products-notification-type").click
      check "Allegation"
      click_button "Apply"

      expect(page).not_to have_content(lift_product_1.name)
      expect(page).not_to have_content(lift_product_2.name)
      expect(page).not_to have_content(furniture_product.name)
      expect(page).not_to have_content(sanitiser_product.name)
      expect(page).not_to have_content("#{retired_sanitiser_product.name} (Retired product record)")
      expect(page).to have_content(allegation_product.name)
      expect(page).to have_content("1 product using the current filters, was found.")
    end
  end
end
