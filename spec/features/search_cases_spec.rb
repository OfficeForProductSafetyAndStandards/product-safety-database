require "rails_helper"

RSpec.feature "Searching cases", :with_elasticsearch, :with_stubbed_mailer, type: :feature do
  let(:user) { create :user, :activated, has_viewed_introduction: true }

  let(:product) do
    create(:product,
           name: "MyBrand washing machine",
           category: "kitchen appliances",
           product_code: "W2020-10/1")
  end
  let!(:investigation) { create(:allegation, products: [product]) }

  let(:mobile_phone) do
    create(:product,
           name: "T12 mobile phone",
           category: "consumer electronics")
  end
  let!(:mobile_phone_investigation) { create(:allegation, products: [mobile_phone]) }

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

  scenario "searching for a case using a close-matching product name keyword" do
    sign_in(user)
    visit "/cases"

    fill_in "Keywords", with: "MyBran"
    click_button "Search"

    expect_to_be_on_cases_search_results_page(search_term: "MyBran")

    expect(page).to have_text(investigation.pretty_id)
    expect(page).to have_text("MyBrand washing machine")
  end

  scenario "searching for a case using an exact matching product code" do
    sign_in(user)
    visit "/cases"

    fill_in "Keywords", with: "W2020-10/1"
    click_button "Search"

    expect_to_be_on_cases_search_results_page(search_term: "W2020-10/1")

    expect(page).to have_text(investigation.pretty_id)
    expect(page).to have_text("MyBrand washing machine")
  end

  scenario "searching for cases using multiple keywords" do
    sign_in(user)
    visit "/cases"

    fill_in "Keywords", with: "mybrand mobile phone"
    click_button "Search"

    expect_to_be_on_cases_search_results_page(search_term: "mybrand mobile phone")

    # Both cases returned even though neither matches ALL the keywords
    expect(page).to have_text(investigation.pretty_id)
    expect(page).to have_text("MyBrand washing machine")

    expect(page).to have_text(mobile_phone_investigation.pretty_id)
    expect(page).to have_text("T12 mobile phone")
  end
end
