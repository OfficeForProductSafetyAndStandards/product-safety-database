require "rails_helper"

RSpec.feature "Product filtering", :with_opensearch, :with_stubbed_mailer, type: :feature do
  let(:organisation)          { create(:organisation) }
  let(:user)                  { create(:user, :activated, organisation:, has_viewed_introduction: true) }
  let(:opss_user)             { create(:user, :opss_user, :activated, organisation:, has_viewed_introduction: true) }

  let!(:chemical_investigation)              { create(:allegation, hazard_type: "Chemical") }
  let!(:fire_investigation)                  { create(:allegation, hazard_type: "Fire") }
  let!(:drowning_investigation)              { create(:allegation, hazard_type: "Drowning") }

  let!(:fire_product_1)   { create(:product, name: "Hot product", investigations: [fire_investigation]) }
  let!(:fire_product_2)   { create(:product, name: "Very hot product", investigations: [fire_investigation]) }
  let!(:chemical_product) { create(:product, name: "Some lab stuff", investigations: [chemical_investigation]) }
  let!(:drowning_product) { create(:product, name: "Dangerous life vest", investigations: [drowning_investigation]) }
  let!(:retired_drowning_product) { create(:product, name: "Dangerous retired life vest", investigations: [drowning_investigation], retired_at: Time.zone.now) }

  before do
    Investigation.import scope: "not_deleted", refresh: :wait_for
    Product.import refresh: :wait_for
  end

  context "when user is non OPSS" do
    before do
      sign_in(user)
      visit products_path
    end

    scenario "no filters applied shows all non-retired products" do
      expect(page).to have_content(fire_product_1.name)
      expect(page).to have_content(fire_product_2.name)
      expect(page).to have_content(chemical_product.name)
      expect(page).to have_content(drowning_product.name)
      expect(page).to have_content("There are currently 4 products.")
    end

    context "when there are multiple pages of products" do
      before do
        17.times { Product.create(name: "TestProduct") }
        Product.import refresh: :wait_for
        visit products_path
      end

      it "shows total number of products regardless of how many are on the current page" do
        expect(page).to have_content("There are currently #{Product.not_retired.count} products.")
      end
    end

    scenario "filtering by hazard type" do
      select "Fire", from: "Hazard type"
      click_button "Apply"

      expect(page).to have_content(fire_product_1.name)
      expect(page).to have_content(fire_product_2.name)
      expect(page).not_to have_content(chemical_product.name)
      expect(page).not_to have_content(drowning_product.name)
      expect(page).not_to have_content(retired_drowning_product.name)
      expect(page).to have_content("2 products using the current filters, were found.")
    end

    scenario "filtering by hazard type and a keyword" do
      select "Fire", from: "Hazard type"
      fill_in "Search", with: "Fire"
      click_button "Apply"

      expect(page).to have_content(fire_product_1.name)
      expect(page).to have_content(fire_product_2.name)
      expect(page).not_to have_content(chemical_product.name)
      expect(page).not_to have_content(drowning_product.name)
      expect(page).not_to have_content(retired_drowning_product.name)
      expect(page).to have_content("2 products matching keyword(s) Fire, using the current filters, were found.")
    end

    scenario "filtering by a keyword" do
      fill_in "Search", with: "Dangerous"
      click_button "Apply"

      expect(page).to have_content(drowning_product.name)
      expect(page).not_to have_content(retired_drowning_product.name)
      expect(page).not_to have_content(fire_product_1.name)
      expect(page).not_to have_content(fire_product_2.name)
      expect(page).not_to have_content(chemical_product.name)
      expect(page).to have_content("1 product matching keyword(s) Dangerous, was found.")
    end

    scenario "filtering by a keyword with whitespaces" do
      fill_in "Search", with: "   Dangerous    "
      click_button "Apply"

      expect(page).to have_content(drowning_product.name)
      expect(page).not_to have_content(retired_drowning_product.name)
      expect(page).not_to have_content(fire_product_1.name)
      expect(page).not_to have_content(fire_product_2.name)
      expect(page).not_to have_content(chemical_product.name)
      expect(page).to have_content("1 product matching keyword(s) Dangerous, was found.")
    end

    scenario "filtering by an ID" do
      fill_in "Search", with: chemical_product.id
      click_button "Apply"

      expect(page).to have_content(chemical_product.name)
    end

    scenario "filtering by a PSD ref" do
      fill_in "Search", with: chemical_product.psd_ref
      click_button "Apply"

      expect(page).to have_content(chemical_product.name)
    end
  end

  context "when user is OPSS" do
    before do
      sign_in(opss_user)
      visit products_path
    end

    scenario "no filters applied shows all non-retired products" do
      expect(page).to have_content(fire_product_1.name)
      expect(page).to have_content(fire_product_2.name)
      expect(page).to have_content(chemical_product.name)
      expect(page).to have_content(drowning_product.name)
      expect(page).not_to have_content(retired_drowning_product.name)
      expect(page).to have_content("There are currently 4 products.")
    end

    scenario "filtering by active products" do
      within_fieldset("Product record status") { choose "Active" }
      click_button "Apply"

      expect(page).to have_content(fire_product_1.name)
      expect(page).to have_content(fire_product_2.name)
      expect(page).to have_content(chemical_product.name)
      expect(page).to have_content(drowning_product.name)
      expect(page).not_to have_content(retired_drowning_product.name)
      expect(page).to have_content("4 products using the current filters, were found.")
    end

    scenario "filtering by retired products" do
      within_fieldset("Product record status") { choose "Retired" }
      click_button "Apply"

      expect(page).not_to have_content(fire_product_1.name)
      expect(page).not_to have_content(fire_product_2.name)
      expect(page).not_to have_content(chemical_product.name)
      expect(page).not_to have_content(drowning_product.name)
      expect(page).to have_content("#{retired_drowning_product.name}(Retired product record)")
      expect(page).to have_content("1 product using the current filters, was found.")
    end

    scenario "filtering by both retired and active products" do
      within_fieldset("Product record status") { choose "All" }
      click_button "Apply"

      expect(page).to have_content(fire_product_1.name)
      expect(page).to have_content(fire_product_2.name)
      expect(page).to have_content(chemical_product.name)
      expect(page).to have_content(drowning_product.name)
      expect(page).to have_content("#{retired_drowning_product.name}(Retired product record)")
      expect(page).to have_content("5 products using the current filters, were found.")
    end
  end
end
