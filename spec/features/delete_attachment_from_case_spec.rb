require "rails_helper"

RSpec.feature "Deleting an attachment from a case", :with_stubbed_antivirus, :with_stubbed_mailer, type: :feature do
  let(:user) { create(:user, :activated, has_viewed_introduction: true) }
  let(:investigation) { create(:allegation, :with_antivirus_checked_image, creator: user) }
  let(:document) { investigation.documents.first }

  before { sign_in(user) }

  scenario "deletes the attachment and creates activity" do
    visit "/cases/#{investigation.pretty_id}/supporting-information"

    expect_to_be_on_supporting_information_page(case_id: investigation.pretty_id)
    click_link "Images (1)"
    expect(page).to have_selector("figure figcaption", text: document.decorate.title)
    expect(page).to have_selector("dd.govuk-summary-list__value", text: document.description)
    click_link "Remove this image: #{document.decorate.title}"

    expect_remove_attachment_confirmation_page_to_show_attachment_information

    click_button "Delete attachment"

    expect_to_be_on_images_page
    click_link "Supporting information"

    expect_case_supporting_informartion_page_not_to_show_deleted_attachment
    click_link "Activity"

    expect_case_activity_page_to_show_deleted_document
  end

  def expect_remove_attachment_confirmation_page_to_show_attachment_information
    expect(page.find("th", text: "Title")).to have_sibling("td", text: document.title)
    expect(page.find("th", text: "Description")).to have_sibling("td", text: document.description)
    expect(page.find("th", text: "URL")).to have_sibling("td", text: document.filename)
  end

  def expect_case_supporting_informartion_page_not_to_show_deleted_attachment
    expect(page).not_to have_selector("figure figcaption", text: document.title)
    expect(page).not_to have_selector("dd.govuk-summary-list__value", text: document.description)
  end

  def expect_case_activity_page_to_show_deleted_document
    expect(page).to have_selector("h1", text: "Activity")
    item = page.find("h3", text: document.title).find(:xpath, "..")
    expect(item).to have_selector("p", text: "Image deleted")
  end
end
