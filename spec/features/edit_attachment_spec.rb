require "rails_helper"

RSpec.feature "Editing an attachment on a case", :with_stubbed_antivirus, :with_stubbed_mailer, type: :feature do
  let(:user) { create(:user, :activated, has_viewed_introduction: true) }
  let(:investigation) { create(:allegation, :with_document, creator: user) }
  let(:document) { investigation.documents.first }

  let(:new_title) { Faker::Lorem.sentence }
  let(:new_description) { Faker::Lorem.paragraph }

  before do
    sign_in(user)
    visit edit_investigation_document_path(investigation, document)
  end

  scenario "saves changes and creates activity" do
    expect_to_be_on_edit_attachment_page

    fill_and_submit_attachment_details_page

    click_link "Supporting information (1)"

    expect(page).to have_css("dd.govuk-summary-list__value", text: new_title)

    click_link "Activity"

    expect_case_activity_page_to_show_entered_information
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
