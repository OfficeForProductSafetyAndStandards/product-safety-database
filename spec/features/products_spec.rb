require "rails_helper"

RSpec.feature "Products listing", :with_stubbed_mailer, type: :feature do
  let(:user)             { create :user, :activated, has_viewed_introduction: true }
  let!(:iphone)          { create(:product_iphone,          brand: "Apple", created_at: 1.day.ago, authenticity: "counterfeit") }
  let!(:iphone_3g)       { create(:product_iphone_3g,       brand: "Apple", created_at: 2.days.ago, authenticity: "genuine") }
  let!(:product_samsung) { create(:product_samsung,         brand: "Samsung", created_at: 2.days.ago, authenticity: "genuine") }
  let!(:washing_machine) { create(:product_washing_machine, brand: "Whirlpool", created_at: 3.days.ago, authenticity: "unsure") }
  let!(:investigation)    { create(:allegation, products: [iphone], hazard_type: "Cuts") }

  context "with less than 12 products" do
    before do
      sign_in(user)
    end

    scenario "does not display pagination on the product list" do
      visit products_path
      expect(page).not_to have_css(".govuk-pagination__link")
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
      visit all_products_path

      within "#item-0" do
        expect(page).to have_link(iphone.name, href: product_path(iphone))
      end

      expect(psd_ref.text).to eq iphone.psd_ref
      expect(subcategory.text).to eq iphone.subcategory
      expect(category.text).to eq iphone.category
      expect_correct_counterfeit_values

      within "#item-1" do
        expect(page).to have_link(product_samsung.name, href: product_path(product_samsung))
      end

      within "#item-2" do
        expect(page).to have_link(iphone_3g.name, href: product_path(iphone_3g))
      end

      expect(page).to have_css("tfoot")

      expect(page).to have_css(".govuk-pagination__link", text: "1")
      expect(page).to have_link("Next", href: all_products_path(page: 2))

      fill_in "Search", with: iphone.name
      click_on "Submit search"

      within "#item-0" do
        expect(page).to have_link(iphone.name, href: product_path(iphone))
      end

      fill_in "Search", with: "Whirlpool"
      click_on "Submit search"

      within "#item-0" do
        expect(page).to have_link(washing_machine.name, href: product_path(washing_machine))
      end

      fill_in "Search", with: "Samsung"
      click_on "Submit search"

      within "#item-0" do
        expect(page).to have_link(product_samsung.name, href: product_path(product_samsung))
      end
    end

    scenario "displays cases for product" do
      visit "/products/#{iphone.id}"
      expect(page).to have_text("This product record has been added to 1 notification")

      within ".capy-cases" do
        expect(page).to have_link(investigation.title, href: "/cases/#{investigation.pretty_id}")
        expect(page).to have_css("dd", text: investigation.pretty_id)
        expect(page).to have_css("dd", text: investigation.owner_team.name)
      end
      investigation.update!(is_private: true)
      visit "/products/#{iphone.id}"

      expect(page).to have_text("This product record has been added to 1 notification")

      within ".capy-cases" do
        expect(page).to have_css("dt", text: "Notification restricted")
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
      expect(counterfeit(2).text).to eq "No"
      expect(counterfeit(3).text).to eq "Unsure"
    end
  end
end
