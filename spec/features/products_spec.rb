require "rails_helper"

RSpec.feature "Products listing", :with_elasticsearch, :with_stubbed_mailer, type: :feature do
  let(:user)             { create :user, :activated, has_viewed_introduction: true }
  let!(:iphone)          { create(:product_iphone,          created_at: 1.day.ago) }
  let!(:iphone_3g)       { create(:product_iphone_3g,       created_at: 2.days.ago) }
  let!(:washing_machine) { create(:product_washing_machine, created_at: 3.days.ago) }

  before do
    create_list(:product, 18, created_at: 4.days.ago)
    sign_in(user)
  end

  scenario "lists products according to search relevance" do
    Product.import refresh: :wait_for
    visit products_path

    within ".govuk-grid-row.psd-product-card:nth-child(1) > .govuk-grid-column-one-half:nth-child(1) > span:nth-child(2)" do
      expect(page).to have_link(iphone.name, href: product_path(iphone))
    end

    within ".govuk-grid-row.psd-product-card:nth-child(2) > .govuk-grid-column-one-half:nth-child(1) > span:nth-child(2)" do
      expect(page).to have_link(iphone_3g.name, href: product_path(iphone_3g))
    end

    within ".govuk-grid-row.psd-product-card:nth-child(3) > .govuk-grid-column-one-half:nth-child(1) > span:nth-child(2)" do
      expect(page).to have_link(washing_machine.name, href: product_path(washing_machine))
    end

    expect(page).to have_css(".pagination em.current", text: 1)
    expect(page).to have_link("2", href: products_path(page: 2))
    expect(page).to have_link("Next →", href: products_path(page: 2))

    fill_in "Keywords", with: iphone.name
    click_on "Search"

    within ".govuk-grid-row.psd-product-card:nth-child(1) > .govuk-grid-column-one-half:nth-child(1) > span:nth-child(2)" do
      expect(page).to have_link(iphone.name, href: product_path(iphone))
    end

    within ".govuk-grid-row.psd-product-card:nth-child(2) > .govuk-grid-column-one-half:nth-child(1) > span:nth-child(2)" do
      expect(page).to have_link(iphone_3g.name, href: product_path(iphone_3g))
    end
  end

  scenario "displays cases for product" do
    investigation = create(:allegation, :with_products, products: [iphone])
    visit "/products/#{iphone.id}"
    within ".psd-case-card" do
      expect(page).to have_link(investigation.title, href: "/cases/#{investigation.pretty_id}")
    end
    investigation.update!(is_private: true)
    visit "/products/#{iphone.id}"
    within ".psd-case-card" do
      expect(page).to have_css("span", text: "Allegation restricted")
    end
  end
end
