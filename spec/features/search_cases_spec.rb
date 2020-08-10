require "rails_helper"

RSpec.feature "Searching cases", :with_elasticsearch, :with_stubbed_mailer, type: :feature do
  let(:user) { create :user, :activated, has_viewed_introduction: true }
  let(:product) { create(:product, name: "MyBrand washing machine") }
  let!(:investigation) { create(:allegation, products: [product]) }

  before do
    # Import products syncronously into ElasticSearch
    Investigation.import refresh: :wait_for
  end

  scenario "searching for a case using a keyword from a product name" do
    sign_in(user)
    visit "/cases"

    fill_in "Keywords", with: "MyBrand"
    click_button "Search"

    expect_to_be_on_cases_search_results_page(search_term: "MyBrand")

    expect(page).to have_text(investigation.pretty_id)

    # Full product name should be shown
    expect(page).to have_text("MyBrand washing machine")

    # The part of the product name which matches the search term should be highlighted
    expect(page).to have_selector("em", text: "MyBrand")
  end
end
