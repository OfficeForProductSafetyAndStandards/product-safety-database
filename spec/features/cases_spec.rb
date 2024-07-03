require "rails_helper"

RSpec.feature "Investigation listing", :with_opensearch, :with_stubbed_mailer, type: :feature do
  let(:user) { create :user, :activated, has_viewed_introduction: true }
  let(:pagination_link_params) do
    {
      page: 2
    }
  end

  let!(:investigation_last_updated_3_days_ago) { create(:notification, description: "Electric skateboard investigation").decorate }
  let!(:investigation_last_updated_2_days_ago) { create(:notification, description: "FastToast toaster investigation").decorate }
  let!(:investigation_last_updated_1_days_ago) { create(:notification, description: "Counterfeit chargers investigation").decorate }

  before do
    allow(AuditActivity::Investigation::Base).to receive(:from)
    create_list :notification, 18

    Investigation::Notification.update_all(updated_at: 4.days.ago)
    investigation_last_updated_3_days_ago.update!(updated_at: 3.days.ago)
    investigation_last_updated_2_days_ago.update!(updated_at: 2.days.ago)
    investigation_last_updated_1_days_ago.update!(updated_at: 1.day.ago)
  end

  scenario "lists cases correctly sorted" do
    # it is necessary to re-import and wait for the indexing to be done.
    Investigation.reindex

    sign_in(user)
    visit all_cases_investigations_path

    # Expect investigations to be in reverse chronological order
    expect(page)
      .to have_css("tbody.govuk-table__body:nth-child(3) tr.govuk-table__row td.govuk-table__cell", text: investigation_last_updated_1_days_ago.pretty_id)
    expect(page)
      .to have_css("tbody.govuk-table__body:nth-child(4) tr.govuk-table__row td.govuk-table__cell", text: investigation_last_updated_2_days_ago.pretty_id)
    expect(page)
      .to have_css("tbody.govuk-table__body:nth-child(5) tr.govuk-table__row td.govuk-table__cell", text: investigation_last_updated_3_days_ago.pretty_id)

    expect(page).to have_css(".govuk-pagination__link", text: "1")

    fill_in "Search", with: "electric skateboard"
    click_on "Apply"

    # Expect only the single relevant investigation to be returned
    expect(page)
      .to have_css("tbody.govuk-table__body:nth-child(3) tr.govuk-table__row td.govuk-table__cell", text: investigation_last_updated_3_days_ago.pretty_id)

    expect(page.find("select#sort_by option", text: "Relevance")).to be_selected
    expect(page).to have_css("form#cases-search-form dl.opss-dl-select dd", text: "Active: Relevance")

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

    within("form#cases-search-form dl.opss-dl-select") do
      click_on "Oldest updates"
    end
    expect(page).to have_current_path(/sort_by=updated_at&sort_dir=asc/, ignore_query: false)

    expect(page.find("select#sort_by option", text: "Oldest updates")).to be_selected
    expect(page).to have_css("form#cases-search-form dl.opss-dl-select dd", text: "Active: Oldest updates")
  end
end
