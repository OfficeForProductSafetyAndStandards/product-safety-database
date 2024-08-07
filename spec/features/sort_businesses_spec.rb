require "rails_helper"

RSpec.feature "Business sorting", :with_stubbed_mailer, type: :feature do
  let(:organisation)          { create(:organisation) }
  let(:user)                  { create(:user, :activated, organisation:, has_viewed_introduction: true) }

  let!(:chemical_investigation)              { create(:allegation, hazard_type: "Chemical") }
  let!(:fire_investigation)                  { create(:allegation, hazard_type: "Fire") }
  let!(:drowning_investigation)              { create(:allegation, hazard_type: "Drowning") }
  # rubocop:disable RSpec/LetSetup
  let!(:business_a)   { create(:business, trading_name: "AA Business", investigations: [chemical_investigation]) }
  let!(:business_b)   { create(:business, trading_name: "CC Business", investigations: [fire_investigation]) }
  let!(:business_c)   { create(:business, trading_name: "BB Business", investigations: [drowning_investigation]) }
  let!(:business_d)   { create(:business, trading_name: "DD Business", investigations: [drowning_investigation]) }
  let!(:business_e)   { create(:business, trading_name: "EE Business", investigations: [drowning_investigation]) }
  let!(:business_f)   { create(:business, trading_name: "FF Business", investigations: [drowning_investigation]) }
  let!(:business_g)   { create(:business, trading_name: "GG Business", investigations: [drowning_investigation]) }
  let!(:business_h)   { create(:business, trading_name: "HH Business", investigations: [drowning_investigation]) }
  let!(:business_i)   { create(:business, trading_name: "II Business", investigations: [drowning_investigation]) }
  let!(:business_j)   { create(:business, trading_name: "JJ Business", investigations: [drowning_investigation]) }
  let!(:business_k)   { create(:business, trading_name: "KK Business", investigations: [drowning_investigation]) }
  let!(:business_l)   { create(:business, trading_name: "ZZ Business", investigations: [drowning_investigation]) }
  let!(:business_m)   { create(:business, trading_name: "MM Business", investigations: [drowning_investigation]) }
  # rubocop:enable RSpec/LetSetup

  before do
    Investigation.reindex
    sign_in(user)
    visit businesses_path
  end

  scenario "no filters applied sorts by Recently added" do
    expect(page).to have_css("form dl.opss-dl-select dd", text: "Active: Newly added")

    expect(page).to have_css("table tbody.govuk-table__body > tr:nth-child(1) > th:nth-child(1)", text: business_m.trading_name)
    expect(page).to have_css("table tbody.govuk-table__body > tr:nth-child(2) > th:nth-child(1)", text: business_l.trading_name)
    expect(page).to have_css("table tbody.govuk-table__body > tr:nth-child(3) > th:nth-child(1)", text: business_k.trading_name)
    expect(page).to have_css("table tbody.govuk-table__body > tr:nth-child(4) > th:nth-child(1)", text: business_j.trading_name)
    expect(page).to have_css("table tbody.govuk-table__body > tr:nth-child(5) > th:nth-child(1)", text: business_i.trading_name)
  end

  scenario "selecting Name A–Z sorts ascending by name" do
    within "form dl.govuk-list.opss-dl-select" do
      click_on "Name A–Z"
    end
    expect(page).to have_current_path(/sort_by=name/, ignore_query: false)
    expect(page).to have_current_path(/sort_dir=asc/, ignore_query: false)
    expect(page).to have_css("form dl.opss-dl-select dd", text: "Active: Name A–Z")

    expect(page).to have_css("table tbody.govuk-table__body > tr:nth-child(1) > th:nth-child(1)", text: business_a.trading_name)
    expect(page).to have_css("table tbody.govuk-table__body > tr:nth-child(2) > th:nth-child(1)", text: business_c.trading_name)
    expect(page).to have_css("table tbody.govuk-table__body > tr:nth-child(3) > th:nth-child(1)", text: business_b.trading_name)
    expect(page).to have_css("table tbody.govuk-table__body > tr:nth-child(4) > th:nth-child(1)", text: business_d.trading_name)
    expect(page).to have_css("table tbody.govuk-table__body > tr:nth-child(5) > th:nth-child(1)", text: business_e.trading_name)
  end

  scenario "selecting Name Z–A sorts descending by name" do
    within "form dl.govuk-list.opss-dl-select" do
      click_on "Name Z–A"
    end
    expect(page).to have_current_path(/sort_by=name/, ignore_query: false)
    expect(page).to have_current_path(/sort_dir=desc/, ignore_query: false)
    expect(page).to have_css("form dl.opss-dl-select dd", text: "Active: Name Z–A")

    expect(page).to have_css("table tbody.govuk-table__body > tr:nth-child(1) > th:nth-child(1)", text: business_l.trading_name)
    expect(page).to have_css("table tbody.govuk-table__body > tr:nth-child(2) > th:nth-child(1)", text: business_m.trading_name)
    expect(page).to have_css("table tbody.govuk-table__body > tr:nth-child(3) > th:nth-child(1)", text: business_k.trading_name)
    expect(page).to have_css("table tbody.govuk-table__body > tr:nth-child(4) > th:nth-child(1)", text: business_j.trading_name)
    expect(page).to have_css("table tbody.govuk-table__body > tr:nth-child(5) > th:nth-child(1)", text: business_i.trading_name)
  end

  scenario "filtering by keyword sorts by Relevance by default" do
    fill_in "Search", with: "Business"
    click_button "Submit search"

    expect(page).to have_css("form dl.govuk-list.opss-dl-select dd", text: "Active: Relevance")

    fill_in "Search", with: "CC"
    click_button "Submit search"

    expect(page).to have_current_path(/sort_by=relevant/, ignore_query: false)
  end

  scenario "filtering by keyword persists a selected sort order" do
    within "form dl.govuk-list.opss-dl-select" do
      click_on "Name A–Z"
    end

    fill_in "Search", with: "Business"
    click_button "Submit search"

    expect(page).to have_current_path(/sort_by=name/, ignore_query: false)
    expect(page).to have_css("form dl.govuk-list.opss-dl-select dd", text: "Active: Name A–Z")
  end
end
