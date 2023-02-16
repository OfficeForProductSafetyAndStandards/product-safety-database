require "rails_helper"

RSpec.feature "Products listing", :with_opensearch, :with_stubbed_mailer, type: :feature do
  let(:user)             { create :user, :activated, has_viewed_introduction: true }
  let!(:iphone)          { create(:product_iphone,          created_at: 1.day.ago, authenticity: "counterfeit") }
  let!(:iphone_3g)       { create(:product_iphone_3g,       created_at: 2.days.ago, authenticity: "genuine") }
  let!(:washing_machine) { create(:product_washing_machine, created_at: 3.days.ago, authenticity: "unsure") }
  let!(:investigation)    { create(:allegation, products: [iphone], hazard_type: "Cuts") }

  context "with less than 12 products" do
    before do
      create_list(:product, 8, created_at: 4.days.ago)
      sign_in(user)
    end

    scenario "does not display pagination on the product list" do
      visit products_path
      expect(page).not_to have_css("nav.opss-pagination-link")
    end

    scenario "does not display a table footer on the product list" do
      visit products_path
      expect(page).not_to have_css("tfoot")
    end
  end

  context "with over 20 products" do
    before do
      create_list(:product, 18, created_at: 4.days.ago)
      sign_in(user)
    end

    scenario "lists products according to search relevance" do
      Product.import refresh: :wait_for
      visit products_path

      within "#item-0" do
        expect(page).to have_link(iphone.name, href: product_path(iphone))
      end

      expect(psd_ref.text).to eq iphone.psd_ref
      expect(subcategory.text).to eq iphone.subcategory
      expect(category.text).to eq iphone.category
      expect_correct_counterfeit_values

      within "#item-1" do
        expect(page).to have_link(iphone_3g.name, href: product_path(iphone_3g))
      end

      within "#item-2" do
        expect(page).to have_link(washing_machine.name, href: product_path(washing_machine))
      end

      expect(page).to have_css("tfoot")

      expect(page).to have_css("nav.opss-pagination-link .opss-pagination-link--text", text: "Page 1")
      expect(page).to have_link("Next page", href: all_products_path(page: 2))

      pending 'this will be fixed once we re-add fuzzy "or" matching on'

      fill_in "Search", with: iphone.name
      click_on "Search"

      within "#item-0" do
        expect(page).to have_link(iphone.name, href: product_path(iphone))
      end

      within "#item-1" do
        expect(page).to have_link(iphone.name, href: product_path(iphone))
      end
    end

    scenario "displays cases for product" do
      visit "/products/#{iphone.id}"
      expect(page).to have_text("This product record has been added to 1 case")

      within ".capy-cases" do
        expect(page).to have_link(investigation.title, href: "/cases/#{investigation.pretty_id}")
        expect(page).to have_css("dd", text: investigation.pretty_id)
        expect(page).to have_css("dd", text: investigation.owner_team.name)
      end
      investigation.update!(is_private: true)
      visit "/products/#{iphone.id}"

      expect(page).to have_text("This product record has been added to 1 case")

      within ".capy-cases" do
        expect(page).to have_css("dt", text: "Allegation restricted")
        expect(page).not_to have_css("dd", text: investigation.pretty_id)
        expect(page).not_to have_css("dd", text: investigation.owner_team.name)
      end
    end

    context "when over 10k cases exist" do
      before do
        not_retired_products_double = instance_double("not_retired_products")
        allow(Product).to receive(:not_retired).and_return(not_retired_products_double)
        allow(not_retired_products_double).to receive(:count).and_return(10_001)
      end

      it "shows total number of cases" do
        visit products_path
        expect(page).to have_content "There are currently 10001 products."
      end
    end

    def psd_ref
      find('[headers="psdref item-0 meta-0"]')
    end

    def subcategory
      find('[headers="prodtype item-0 meta-0"]')
    end

    def counterfeit(product_index)
      find("[headers='counterfeit item-#{product_index} meta-#{product_index}']")
    end

    def category
      find("[headers='cat item-0 meta-0']")
    end

    def expect_correct_counterfeit_values
      expect(counterfeit(0).text).to eq "Yes"
      expect(counterfeit(1).text).to eq "No"
      expect(counterfeit(2).text).to eq "Unsure"
    end
  end
end
