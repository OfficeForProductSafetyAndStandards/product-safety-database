require "rails_helper"

RSpec.feature "Deleting an attachment from a case", :with_stubbed_elasticsearch, :with_stubbed_antivirus, :with_stubbed_mailer, type: :feature do
  let(:user) { create(:user, :activated, has_viewed_introduction: true) }
  let(:investigation) { create(:allegation, :with_antivirus_checked_document, owner: user) }
  let(:document) { investigation.documents.first }

  before { sign_in(user) }

  scenario "deletes the attachment and creates activity" do
    visit investigation_attachments_path(investigation)

    expect_to_be_on_attachments_page

    click_link "Remove document"

    expect_to_be_on_remove_attachment_confirmation_page
    expect_remove_attachment_confirmation_page_to_show_attachment_information

    click_button "Delete attachment"

    expect_to_be_on_case_overview_page

    click_link "Attachments"

    expect_case_attachments_page_not_to_show_deleted_attachment

    click_link "Activity"

    expect_case_activity_page_to_show_deleted_document
  end

  def expect_to_be_on_attachments_page
    expect(page).to have_current_path("/cases/#{investigation.pretty_id}/attachments")
    expect(page).to have_selector("h1", text: "Attachments")
    expect(page).to have_selector("h2", text: document.title)
    expect(page).to have_selector("p",  text: document.description)
  end

  def expect_to_be_on_remove_attachment_confirmation_page
    expect(page).to have_current_path("/cases/#{investigation.pretty_id}/documents/#{document.id}/remove")
    expect(page).to have_selector("h2", text: "Remove attachment")
    expect(page).to have_link("Back", href: "/cases/#{investigation.pretty_id}")
  end

  def expect_to_be_on_case_overview_page
    expect(page).to have_current_path("/cases/#{investigation.pretty_id}")
    expect(page).to have_selector("h1", text: "Overview")
  end

  def expect_remove_attachment_confirmation_page_to_show_attachment_information
    expect(page.find("th", text: "Title")).to have_sibling("td", text: document.title)
    expect(page.find("th", text: "Description")).to have_sibling("td", text: document.description)
    expect(page.find("th", text: "URL")).to have_sibling("td", text: document.filename)
  end

  def expect_case_attachments_page_not_to_show_deleted_attachment
    expect(page).not_to have_selector("h2", text: document.title)
    expect(page).not_to have_selector("p",  text: document.description)
  end

  def expect_case_activity_page_to_show_deleted_document
    expect(page).to have_selector("h1", text: "Activity")
    item = page.find("h3", text: document.title).find(:xpath, "..")
    expect(item).to have_selector("p", text: "Document deleted")
  end
end
