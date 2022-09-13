require "rails_helper"

RSpec.feature "Changing the status of a case", :with_opensearch, :with_stubbed_mailer, type: :feature do
  let!(:investigation) { create(:allegation, creator: creator_user, is_closed: false) }
  let(:user) { create(:user, :activated, name: "Jane Jones") }
  let(:creator_user) { create(:user, email: "test@example.com") }

  before do
    ChangeCaseOwner.call!(investigation:, owner: user, user:)
    delivered_emails.clear
  end

  scenario "Closing and re-opening a case via different routes" do
    sign_in user
    visit "/cases/#{investigation.pretty_id}"

    click_link "Close the case"

    expect_to_be_on_close_case_page(case_id: investigation.pretty_id)

    # Navigate via the case overview table
    visit "/cases/#{investigation.pretty_id}"

    within("div.opss-text-align-right") do
      expect(page).to have_link "Close case"
      expect(page).not_to have_link "Re-open case"
      click_link "Close case"
    end

    expect_to_be_on_close_case_page(case_id: investigation.pretty_id)

    fill_in "Why are you closing the case?", with: "Case has been resolved."

    click_button "Close case"

    expect_to_be_on_case_page(case_id: investigation.pretty_id)
    expect_confirmation_banner("Allegation was closed")
    expect(page).to have_summary_item(key: "Status", value: "Case closed #{Date.current.to_s(:govuk)}")

    click_link "Activity"

    expect_to_be_on_case_activity_page(case_id: investigation.pretty_id)
    expect(page).to have_css("h3", text: "Allegation closed")
    expect(page).to have_css("p", text: "Case has been resolved.")

    # Check the close page shows an error if trying to revisit it
    visit "/cases/#{investigation.pretty_id}/status/close"
    expect(page).to have_css("h1", text: "Close case")
    expect(page).to have_css("p", text: "The allegation is already closed. Do you want to re-open it?")

    visit "/cases/#{investigation.pretty_id}"

    within("div.opss-text-align-right") do
      expect(page).not_to have_link "Close case"
      expect(page).to have_link "Re-open case"
      click_link "Re-open case"
    end

    expect_to_be_on_reopen_case_page(case_id: investigation.pretty_id)

    fill_in "Why are you re-opening the case?", with: "Case has not been resolved."

    click_button "Re-open case"

    expect_to_be_on_case_page(case_id: investigation.pretty_id)

    expect_confirmation_banner("Allegation was re-opened")
    expect(page).to have_summary_item(key: "Status", value: "Open")

    click_link "Activity"

    expect_to_be_on_case_activity_page(case_id: investigation.pretty_id)
    expect(page).to have_css("h3", text: "Allegation re-opened")
    expect(page).to have_css("p", text: "Case has not been resolved.")

    # Check the close page shows an error if trying to revisit it
    visit "/cases/#{investigation.pretty_id}/status/reopen"
    expect(page).to have_css("h1", text: "Re-open case")
    expect(page).to have_css("p", text: "The allegation is already open. Do you want to close it?")
  end
end
