require "rails_helper"

RSpec.feature "Product sorting", :with_opensearch, :with_stubbed_mailer, type: :feature do
  let(:organisation)          { create(:organisation) }
  let(:user)                  { create(:user, :opss_user, :activated, organisation:, has_viewed_introduction: true) }

  # rubocop:disable RSpec/LetSetup
  let!(:fire_product_a)   { create(:product, name: "Hot product", category: "Lifts") }
  let!(:fire_product_b)   { create(:product, name: "Xtra hot product", category: "Lifts") }
  let!(:fire_product_c)   { create(:product, name: "Very very hot product", category: "Lifts") }
  let!(:fire_product_d)   { create(:product, name: "Super hot product", category: "Lifts") }
  let!(:fire_product_e)   { create(:product, name: "Extra hot product", category: "Lifts") }
  let!(:fire_product_f)   { create(:product, name: "Firey hot product", category: "Lifts") }
  let!(:fire_product_g)   { create(:product, name: "Mega hot product", category: "Lifts") }
  let!(:fire_product_h)   { create(:product, name: "Crazy hot product", category: "Lifts") }
  let!(:fire_product_i)   { create(:product, name: "Spicy hot product", category: "Lifts") }
  let!(:fire_product_j)   { create(:product, name: "Ultra hot product", category: "Lifts") }
  let!(:fire_product_k)   { create(:product, name: "Intense hot product", category: "Lifts") }
  let!(:fire_product_l)   { create(:product, name: "Smoking hot product", category: "Lifts") }
  let!(:chemical_product) { create(:product, name: "Some lab stuff") }
  let!(:drowning_product) { create(:product, name: "Dangerous life vest") }
  let!(:another_drowning_product) { create(:product, name: "Another dangerous life vest") }
  let!(:zebra_product) { create(:product, name: "Zebra print jacket") }
  # rubocop:enable RSpec/LetSetup

  before do
    Investigation.reindex
    sign_in(user)
    visit products_path
  end

  scenario "no filters applied sorts by Newly added" do
    expect(page).to have_css("form dl.opss-dl-select dd", text: "Active: Newly added")

    expect(page).to have_css("#item-0", text: zebra_product.name)
    expect(page).to have_css("#item-1", text: another_drowning_product.name)
    expect(page).to have_css("#item-2", text: drowning_product.name)
    expect(page).to have_css("#item-3", text: chemical_product.name)
  end

  scenario "selecting Name A-Z sorts ascending by name" do
    within "form dl.govuk-list.opss-dl-select" do
      click_on "Name A-Z"
    end
    expect(page).to have_current_path(/sort_by=name/, ignore_query: false)
    expect(page).to have_current_path(/sort_dir=asc/, ignore_query: false)
    expect(page).to have_css("form dl.opss-dl-select dd", text: "Active: Name A-Z")

    expect(page).to have_css("#item-0", text: another_drowning_product.name)
    expect(page).to have_css("#item-1", text: fire_product_h.name)
    expect(page).to have_css("#item-2", text: drowning_product.name)
    expect(page).to have_css("#item-3", text: fire_product_e.name)
  end

  scenario "selecting Name Z-A sorts descending by name" do
    within "form dl.govuk-list.opss-dl-select" do
      click_on "Name Z-A"
    end
    expect(page).to have_current_path(/sort_by=name/, ignore_query: false)
    expect(page).to have_current_path(/sort_dir=desc/, ignore_query: false)
    expect(page).to have_css("form dl.opss-dl-select dd", text: "Active: Name Z-A")

    expect(page).to have_css("#item-0", text: zebra_product.name)
    expect(page).to have_css("#item-1", text: fire_product_b.name)
    expect(page).to have_css("#item-2", text: fire_product_c.name)
    expect(page).to have_css("#item-3", text: fire_product_j.name)
  end

  scenario "selected sort order is persisted when filtering by category" do
    within "form dl.govuk-list.opss-dl-select" do
      click_on "Name A-Z"
    end

    select "Lifts", from: "Category"
    click_button "Apply"

    expect(page).to have_current_path(/sort_by=name/, ignore_query: false)
    expect(page).to have_css("form dl.govuk-list.opss-dl-select dd", text: "Active: Name A-Z")
  end

  scenario "filtering by keyword sorts by Relevance by default" do
    fill_in "Search", with: "hot product"
    click_button "Apply"

    expect(page).to have_css("form dl.govuk-list.opss-dl-select dd", text: "Active: Relevance")

    select "Lifts", from: "Category"
    click_button "Apply"

    expect(page).to have_current_path(/sort_by=relevant/, ignore_query: false)
    expect(page).to have_css("form dl.govuk-list.opss-dl-select dd", text: "Active: Relevance")
  end

  scenario "filtering by keyword persists a selected sort order" do
    within "form dl.govuk-list.opss-dl-select" do
      click_on "Name A-Z"
    end

    fill_in "Search", with: "hot product"
    click_button "Apply"

    expect(page).to have_current_path(/sort_by=name/, ignore_query: false)
    expect(page).to have_css("form dl.govuk-list.opss-dl-select dd", text: "Active: Name")
  end
end
