require "rails_helper"

RSpec.feature "Adding an attachment to a case", :with_stubbed_elasticsearch, :with_stubbed_antivirus, :with_stubbed_mailer, type: :feature do
  let(:user) { create(:user, :activated, has_viewed_introduction: true) }
  let(:other_user) { create(:user, :activated, has_viewed_introduction: true) }
  let(:investigation) { create(:allegation, :with_antivirus_checked_document, document_has_consumer_info: true, owner: user) }

  scenario "Displays link to view the file" do
    sign_in(user)
    visit "/cases/#{investigation.pretty_id}/attachments"
    expect(page).to have_link("View TXT")
  end

  scenario "Does not link to the file" do
    sign_in(other_user)
    visit "/cases/#{investigation.pretty_id}/attachments"
    expect(page).not_to have_link("View TXT")
  end
end
