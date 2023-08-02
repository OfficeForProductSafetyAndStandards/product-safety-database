require "rails_helper"

RSpec.feature "Investigation listing", :with_opensearch, :with_stubbed_mailer, type: :feature do
  let(:user) { create :user, :activated, has_viewed_introduction: true }
  let(:pagination_link_params) do
    {
      page: 2
    }
  end

  let!(:investigation_last_updated_3_days_ago) { create(:allegation, description: "Electric skateboard investigation").decorate }
  let!(:investigation_last_updated_2_days_ago) { create(:allegation, description: "FastToast toaster investigation").decorate }
  let!(:investigation_last_updated_1_days_ago) { create(:allegation, description: "Counterfeit chargers investigation").decorate }

  before do
    allow(AuditActivity::Investigation::Base).to receive(:from)
    create_list :project, 18

    investigation_last_updated_3_days_ago.update!(updated_at: 3.days.ago)
    investigation_last_updated_2_days_ago.update!(updated_at: 2.days.ago)
    investigation_last_updated_1_days_ago.update!(updated_at: 1.day.ago)
    Investigation::Project.update_all(updated_at: 4.days.ago)
  end

  scenario "lists cases correctly sorted" do
    # it is necessary to re-import and wait for the indexing to be done.
    Investigation.reindex

    sign_in(user)
    visit investigations_path

    # Expect investigations to be in reverse chronological order
    expect(page)
      .to have_css("tbody.govuk-table__body:nth-child(3) tr.govuk-table__row td.govuk-table__cell", text: investigation_last_updated_1_days_ago.pretty_id)
    expect(page)
      .to have_css("tbody.govuk-table__body:nth-child(4) tr.govuk-table__row td.govuk-table__cell", text: investigation_last_updated_2_days_ago.pretty_id)
    expect(page)
      .to have_css("tbody.govuk-table__body:nth-child(5) tr.govuk-table__row td.govuk-table__cell", text: investigation_last_updated_3_days_ago.pretty_id)

    expect(page).to have_css("nav.opss-pagination-link .opss-pagination-link--text", text: "Page 1")

    expect(page).to have_link("Next page", href: /#{Regexp.escape(all_cases_investigations_path(pagination_link_params))}/)

    fill_in "Search", with: "electric skateboard"
    click_on "Apply"

    # Expect only the single relevant investigation to be returned
    expect(page)
      .to have_css("tbody.govuk-table__body:nth-child(3) tr.govuk-table__row td.govuk-table__cell", text: investigation_last_updated_3_days_ago.pretty_id)

    expect(page.find("select#sort_by option", text: "Relevance")).to be_selected
    expect(page).to have_css("form#cases-search-form dl.opss-dl-select dd", text: "Active: Relevance")

    expect(page).to have_current_path(investigations_search_path, ignore_query: true)

    fill_in "Search", with: ""
    click_on "Apply"

    expect(page).not_to have_css("select#sort_by option", text: "Relevance")

    expect(page.find("select#sort_by option", text: "Recent updates")).to be_selected
    expect(page).to have_css("form#cases-search-form dl.opss-dl-select dd", text: "Active: Recent updates")

    # Expect investigations to be back in reverse chronological order again
    expect(page)
      .to have_css("tbody.govuk-table__body:nth-child(3) tr.govuk-table__row td.govuk-table__cell", text: investigation_last_updated_1_days_ago.pretty_id)
    expect(page)
      .to have_css("tbody.govuk-table__body:nth-child(4) tr.govuk-table__row td.govuk-table__cell", text: investigation_last_updated_2_days_ago.pretty_id)
    expect(page)
      .to have_css("tbody.govuk-table__body:nth-child(5) tr.govuk-table__row td.govuk-table__cell", text: investigation_last_updated_3_days_ago.pretty_id)

    expect(page).to have_current_path(investigations_path, ignore_query: true)

    within("form#cases-search-form dl.opss-dl-select") do
      click_on "Oldest updates"
    end
    expect(page).to have_current_path(/sort_by=updated_at&sort_dir=asc/, ignore_query: false)

    expect(page.find("select#sort_by option", text: "Oldest updates")).to be_selected
    expect(page).to have_css("form#cases-search-form dl.opss-dl-select dd", text: "Active: Oldest updates")
  end
end
