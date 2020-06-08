require "rails_helper"

RSpec.feature "Recording a meeting on a case", :with_stubbed_elasticsearch, :with_stubbed_antivirus, :with_stubbed_mailer, type: :feature do
  let(:user) { create(:user, :activated) }
  let(:other_user_same_team) { create(:user, :activated, organisation: user.organisation, team: user.team) }
  let(:other_user_different_org) { create(:user, :activated) }
  let(:investigation) { create(:allegation, owner: user) }
  let(:file) { Rails.root.join("test/fixtures/files/attachment_filename.txt") }

  scenario "Adding a meeting" do
    sign_in(user)

    visit "/cases/#{investigation.pretty_id}/activity"

    click_link "Add activity"

    expect_to_be_on_new_activity_page

    choose "Record meeting"
    click_button "Continue"

    expect_to_be_on_record_meeting_context_page(case_id: investigation.pretty_id)

    fill_in "Who was the meeting with?", with: "Joe Bloggs"

    within_fieldset "Date of meeting" do
      fill_in "Day", with: "2"
      fill_in "Month", with: "4"
      fill_in "Year", with: "2020"
    end

    click_button "Continue"

    expect_to_be_on_record_meeting_content_page(case_id: investigation.pretty_id)

    fill_in "Summary", with: "Meeting with Chief Executive"

    within_fieldset "Details" do
      attach_file "Upload a file", file
      fill_in "Notes", with: "Agreed further meeting in 2 weeks time"
    end

    click_button "Continue"

    expect_to_be_on_confirm_meeting_details_page(case_id: investigation.pretty_id)

    expect(page).to have_summary_table_item(key: "Meeting with", value: "Joe Bloggs")
    expect(page).to have_summary_table_item(key: "Summary", value: "Meeting with Chief Executive")
    expect(page).to have_summary_table_item(key: "Date of meeting", value: "02/04/2020")
    expect(page).to have_summary_table_item(key: "Content", value: "Agreed further meeting in 2 weeks time")

    click_button "Continue"

    expect_to_be_on_case_page(case_id: investigation.pretty_id)

    click_link "Activity"

    expect_to_be_on_case_activity_page(case_id: investigation.pretty_id)

    click_link "View meeting"

    expect_to_be_on_meeting_page(case_id: investigation.pretty_id)

    expect(page).to have_h1("Meeting with Chief Executive")
    expect(page).to have_summary_item(key: "Date", value: "2 April 2020")
    expect(page).to have_summary_item(key: "Meeting with", value: "Joe Bloggs")
    expect(page).to have_summary_item(key: "Notes", value: "Agreed further meeting in 2 weeks time")
  end
end
