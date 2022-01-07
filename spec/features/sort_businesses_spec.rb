require "rails_helper"

RSpec.feature "Business sorting", :with_opensearch, :with_stubbed_mailer, type: :feature do
  let(:organisation)          { create(:organisation) }
  let(:user)                  { create(:user, :activated, organisation: organisation, has_viewed_introduction: true) }

  let!(:chemical_investigation)              { create(:allegation, hazard_type: "Chemical") }
  let!(:fire_investigation)                  { create(:allegation, hazard_type: "Fire") }
  let!(:drowning_investigation)              { create(:allegation, hazard_type: "Drowning") }

  let!(:business_1)   { create(:business, trading_name: "AA Business", investigations: [chemical_investigation]) }
  let!(:business_2)   { create(:business, trading_name: "CC Business", investigations: [fire_investigation]) }
  let!(:business_3)   { create(:business, trading_name: "BB Business", investigations: [drowning_investigation]) }

  before do
    Investigation.import refresh: :wait_for
    Business.import refresh: :wait_for
    sign_in(user)
    visit businesses_path
  end

  scenario "no filters applied sorts by Recently added" do
    expect(page).to have_css("form dl.opss-dl-select dd", text: "Active: Recently added")

    expect(page).to have_css("table#results tbody.govuk-table__body > tr:nth-child(1) > th:nth-child(1)", text: business_3.trading_name)
    expect(page).to have_css("table#results tbody.govuk-table__body > tr:nth-child(2) > th:nth-child(1)", text: business_2.trading_name)
    expect(page).to have_css("table#results tbody.govuk-table__body > tr:nth-child(3) > th:nth-child(1)", text: business_1.trading_name)
  end

  scenario "selecting Name A–Z sorts ascending by name" do
    within "form dl.govuk-list.opss-dl-select" do
      click_on "Name A–Z"
    end
    expect(page).to have_current_path(/sort_by=name/, ignore_query: false)
    expect(page).to have_current_path(/sort_dir=asc/, ignore_query: false)
    expect(page).to have_css("form dl.opss-dl-select dd", text: "Active: Name A–Z")

    expect(page).to have_css("table#results tbody.govuk-table__body > tr:nth-child(1) > th:nth-child(1)", text: business_1.trading_name)
    expect(page).to have_css("table#results tbody.govuk-table__body > tr:nth-child(2) > th:nth-child(1)", text: business_3.trading_name)
    expect(page).to have_css("table#results tbody.govuk-table__body > tr:nth-child(3) > th:nth-child(1)", text: business_2.trading_name)
  end

  scenario "selecting Name Z–A sorts descending by name" do
    within "form dl.govuk-list.opss-dl-select" do
      click_on "Name Z–A"
    end
    expect(page).to have_current_path(/sort_by=name/, ignore_query: false)
    expect(page).to have_current_path(/sort_dir=desc/, ignore_query: false)
    expect(page).to have_css("form dl.opss-dl-select dd", text: "Active: Name Z–A")

    expect(page).to have_css("table#results tbody.govuk-table__body > tr:nth-child(1) > th:nth-child(1)", text: business_2.trading_name)
    expect(page).to have_css("table#results tbody.govuk-table__body > tr:nth-child(2) > th:nth-child(1)", text: business_3.trading_name)
    expect(page).to have_css("table#results tbody.govuk-table__body > tr:nth-child(3) > th:nth-child(1)", text: business_1.trading_name)
  end

  scenario "filtering by keyword sorts by Relevance by default" do
    fill_in "Keywords search", with: "Business"
    click_button "Search"

    expect(page).to have_css("form dl.govuk-list.opss-dl-select dd", text: "Active: Relevance")

    fill_in "Keywords search", with: "CC"
    click_button "Search"

    expect(page).to have_current_path(/sort_by=relevant/, ignore_query: false)
    expect(page).to have_css("form dl.govuk-list.opss-dl-select dd", text: "Active: Relevance")
  end

  scenario "filtering by keyword persists a selected sort order" do
    within "form dl.govuk-list.opss-dl-select" do
      click_on "Name A–Z"
    end

    fill_in "Keywords search", with: "Business"
    click_button "Search"

    expect(page).to have_current_path(/sort_by=name/, ignore_query: false)
    expect(page).to have_css("form dl.govuk-list.opss-dl-select dd", text: "Active: Name A–Z")
  end
end
