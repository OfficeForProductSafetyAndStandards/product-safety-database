require "rails_helper"

RSpec.feature "Recording a meeting on a case", :with_stubbed_elasticsearch, :with_stubbed_antivirus, :with_stubbed_mailer, type: :feature do
  let(:user) { create(:user, :activated) }
  let(:other_user_same_team) { create(:user, :activated, organisation: user.organisation, team: user.team) }
  let(:other_user_different_org) { create(:user, :activated) }
  let(:investigation) { create(:allegation, owner: user) }
  let(:file) { Rails.root.join("test/fixtures/files/attachment_filename.txt") }

  scenario "Adding a meeting using a transcript file (and notes)" do
    sign_in(user)

    visit "/cases/#{investigation.pretty_id}/supporting-information"
    click_link "Add supporting information"

    expect_to_be_on_add_supporting_information_page
    choose "Correspondence"
    click_button "Continue"

    expect_to_be_on_add_correspondence_page
    choose "Record meeting"
    click_button "Continue"

    expect_to_be_on_record_meeting_context_page(case_id: investigation.pretty_id)

    fill_in "Who was the meeting with?", with: "Joe Bloggs"
    # Test that meeting date cannot be future
    within_fieldset "Date of meeting" do
      fill_in "Day", with: "2"
      fill_in "Month", with: "4"
      fill_in "Year", with: "2021"
    end
    click_button "Continue"
    expect(page).to have_summary_error("Correspondence date must be today or in the past")

    within_fieldset "Date of meeting" do
      fill_in "Day", with: "2"
      fill_in "Month", with: "4"
      fill_in "Year", with: "2020"
    end

    click_button "Continue"

    expect_to_be_on_record_meeting_content_page(case_id: investigation.pretty_id)

    # Test that empty meeting form on submit returns expected error message

    click_button "Continue"

    expect(page).to have_summary_error("Please provide either a transcript or complete the summary and notes fields")

    fill_in "Summary", with: "Meeting with Chief Executive"

    within_fieldset "Details" do
      attach_file "Upload a file", file
      fill_in "Notes", with: "Agreed further meeting in 2 weeks time"
    end

    click_button "Continue"

    expect_to_be_on_confirm_meeting_details_page(case_id: investigation.pretty_id)

    expect(page).to have_summary_table_item(key: "Meeting with", value: "Joe Bloggs")
    expect(page).to have_summary_table_item(key: "Summary", value: "Meeting with Chief Executive")
    expect(page).to have_summary_table_item(key: "Date", value: "02/04/2020")
    expect(page).to have_summary_table_item(key: "Content", value: "Agreed further meeting in 2 weeks time")

    click_button "Continue"

    expect_to_be_on_supporting_information_page

    click_link "Activity"

    expect_to_be_on_case_activity_page(case_id: investigation.pretty_id)

    click_link "View meeting"

    expect_to_be_on_meeting_page(case_id: investigation.pretty_id)

    expect(page).to have_h1("Meeting with Chief Executive")
    expect(page).to have_summary_item(key: "Date of meeting", value: "2 April 2020")
    expect(page).to have_summary_item(key: "Meeting with", value: "Joe Bloggs")
    expect(page).to have_summary_item(key: "Notes", value: "Agreed further meeting in 2 weeks time")

    # Test that another user in a different organisation cannot see correspondence info
    sign_out

    sign_in(other_user_different_org)

    visit "/cases/#{investigation.pretty_id}/activity"

    expect_to_be_on_case_activity_page(case_id: investigation.pretty_id)
    expect_case_activity_page_to_show_restricted_information

    # Test that another user in the same team can see correspondence
    sign_out

    sign_in(other_user_same_team)

    visit "/cases/#{investigation.pretty_id}/activity"

    expect_to_be_on_case_activity_page(case_id: investigation.pretty_id)
    expect_case_activity_page_to_show_meeting_information
  end

  scenario "Adding a meeting using just a summary and notes" do
    sign_in(user)

    visit "/cases/#{investigation.pretty_id}/supporting-information"

    click_link "Add supporting information"

    expect_to_be_on_add_supporting_information_page

    choose "Correspondence"
    click_button "Continue"

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
      fill_in "Notes", with: "Agreed further meeting in 2 weeks time"
    end

    click_button "Continue"

    expect_to_be_on_confirm_meeting_details_page(case_id: investigation.pretty_id)

    expect(page).to have_summary_table_item(key: "Meeting with", value: "Joe Bloggs")
    expect(page).to have_summary_table_item(key: "Summary", value: "Meeting with Chief Executive")
    expect(page).to have_summary_table_item(key: "Date", value: "02/04/2020")
    expect(page).to have_summary_table_item(key: "Content", value: "Agreed further meeting in 2 weeks time")

    click_button "Continue"

    expect_to_be_on_supporting_information_page
  end

  def expect_case_activity_page_to_show_restricted_information
    item = page.find("h3", text: "Meeting added").find(:xpath, "..")
    expect(item).to have_text("Meeting recorded by #{user.name} (#{user.team.name}), #{Time.zone.today.strftime('%e %B %Y').lstrip}")
    expect(item).to have_text("Only teams added to the case can view correspondence")
  end

  def expect_case_activity_page_to_show_meeting_information
    item = page.find("p", text: "Meeting recorded by #{user.name}").find(:xpath, "..")
    expect(item).to have_text("Meeting with: Joe Bloggs")
    expect(item).to have_text("Date: 02/04/2020")
  end
end
