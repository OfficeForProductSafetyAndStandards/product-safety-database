require "rails_helper"

RSpec.feature "Adding an attachment to a case", :with_stubbed_elasticsearch, :with_stubbed_antivirus, :with_stubbed_mailer, type: :feature do
  let(:user) { create(:user, :activated, has_viewed_introduction: true) }
  let(:investigation) { create(:allegation, assignable: user) }
  let(:file) { Rails.root + "test/fixtures/files/test_result.txt" }
  let(:title) { Faker::Lorem.sentence }
  let(:description) { Faker::Lorem.paragraph }

  before do
    sign_in(user)
    visit new_investigation_new_path(investigation) # TODO: rename this route
  end

  scenario "requires a file" do
    expect_to_be_on_add_attachment_page

    click_button "Upload"

    expect_to_be_on_add_attachment_page
    expect(page).to have_error_summary("Enter file")
  end

  scenario "requires a title for the document" do
    expect_to_be_on_add_attachment_page

    attach_and_submit_file

    expect_to_be_on_enter_attachment_details_page

    click_button "Save attachment"

    expect_to_be_on_enter_attachment_details_page
    expect(page).to have_error_summary("Enter title")
  end

  scenario "uploading a file without completing the add attachment flow does not save the attachment" do
    expect_to_be_on_add_attachment_page

    attach_and_submit_file

    visit investigation_path(investigation)

    click_link "Attachments"

    expect(page).not_to have_selector("h2")
  end

  scenario "completing the add attachment flow saves the attachment" do
    expect_to_be_on_add_attachment_page

    attach_and_submit_file

    expect_to_be_on_enter_attachment_details_page

    fill_and_submit_attachment_details_page

    expect_to_be_on_case_overview_page

    click_link "Attachments (1)"

    expect_case_attachments_page_to_show_entered_information

    click_link "Activity"

    expect_case_activity_page_to_show_entered_information
  end

  def expect_to_be_on_add_attachment_page
    expect(page).to have_current_path("/cases/#{investigation.pretty_id}/documents/new/upload")
    expect(page).to have_selector("h1", text: "Add attachment")
    expect(page).to have_link("Back", href: investigation_path(investigation))
  end

  def expect_to_be_on_enter_attachment_details_page
    expect(page).to have_current_path("/cases/#{investigation.pretty_id}/documents/new/metadata")
    expect(page).to have_selector("h3", text: "Document details")
    expect(page).to have_link("Back", href: investigation_path(investigation))
  end

  def expect_to_be_on_case_overview_page
    expect(page).to have_current_path("/cases/#{investigation.pretty_id}")
    expect(page).to have_selector("h1", text: "Overview")
  end

  def expect_case_attachments_page_to_show_entered_information
    expect(page).to have_selector("h2", text: title)
    expect(page).to have_selector("p", text: description)
  end

  def expect_case_activity_page_to_show_entered_information
    expect(page).to have_selector("h1", text: "Activity")
    item = page.find("h3", text: title).find(:xpath, "..")
    expect(item).to have_selector("p", text: "Document added")
    expect(item).to have_selector("p", text: description)
  end

  def attach_and_submit_file
    attach_file "document[file][file]", file
    click_button "Upload"
  end

  def fill_and_submit_attachment_details_page
    fill_in "Document title", with: title
    fill_in "Description", with: description
    click_button "Save attachment"
  end
end
