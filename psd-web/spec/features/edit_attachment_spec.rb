require "rails_helper"

RSpec.feature "Editing an attachment on a case", :with_stubbed_elasticsearch, :with_stubbed_antivirus, :with_stubbed_mailer, :with_stubbed_keycloak_config do
  let(:user) { create(:user, :activated) }
  let(:investigation) { create(:allegation, :with_document, assignee: user) }
  let(:document) { investigation.documents.first }

  let(:new_title) { Faker::Lorem.sentence }
  let(:new_description) { Faker::Lorem.paragraph }

  before do
    sign_in(as_user: user)
    visit edit_investigation_document_path(investigation, document)
  end

  scenario "saves changes and creates activity" do
    expect_to_be_on_edit_attachment_page

    fill_and_submit_attachment_details_page

    click_link "Attachments (1)"

    expect_case_attachments_page_to_show_entered_information

    click_link "Activity"

    expect_case_activity_page_to_show_entered_information
  end

  def expect_to_be_on_edit_attachment_page
    expect(page).to have_current_path("/cases/#{investigation.pretty_id}/documents/#{document.to_param}/edit")
    expect(page).to have_selector("h2", text: "Edit document details")
    expect(page).to have_link("Back", href: "/cases/#{investigation.pretty_id}")
  end

  def expect_case_attachments_page_to_show_entered_information
    expect(page).to have_selector("h2", text: new_title)
    expect(page).to have_selector("p",  text: new_description)
  end

  def expect_case_activity_page_to_show_entered_information
    expect(page).to have_selector("h1", text: "Activity")
    item = page.find("h3", text: new_title).find(:xpath, "..")
    expect(item).to have_selector("p", text: "Document details updated")
    expect(item).to have_selector("p", text: new_description)
  end

  def fill_and_submit_attachment_details_page
    fill_in "Document title", with: new_title
    fill_in "Description",    with: new_description
    click_button "Update attachment"
  end
end
