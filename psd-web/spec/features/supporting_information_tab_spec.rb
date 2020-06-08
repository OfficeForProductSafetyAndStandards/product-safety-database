require "rails_helper"

RSpec.feature "Manage supporting information", :with_stubbed_elasticsearch, :with_stubbed_antivirus, :with_stubbed_mailer do
  let(:user)          { create(:user, :activated, has_viewed_introduction: true) }
  let(:investigation) { create(:investigation, :with_document, owner: user.team) }

  include_context "with all types of supporting information"

  context "when the team from the user viewing the information owns the investigation" do
    before { sign_in user }

    scenario "completing the add attachment flow saves the attachment" do
      visit "/cases/#{investigation.pretty_id}"
      click_link "Supporting information"
      expect(page).to have_css("h2", text: corrective_action.documents.first.title)
      expect(page).to have_css("h2", text: email.email_file.decorate.title)
      expect(page).to have_css("h2", text: phone_call.transcript.decorate.title)
      expect(page).to have_css("h2", text: meeting.transcript.decorate.title)
      expect(page).to have_css("h2", text: test_request.documents.first.decorate.title)
      expect(page).to have_css("h2", text: test_result.documents.first.decorate.title)
      expect(page).to have_css("h2", text: investigation.documents.first.title)
    end
  end

  context "when the user does not belong to any of the teams with access to the investigation" do
    let(:other_user) { create(:user, :activated, has_viewed_introduction: true) }

    before { sign_in other_user }

    scenario "viewing the supporting information displays restricted information for the generic attachments" do
      visit "/cases/#{investigation.pretty_id}"
      click_link "Supporting information"
      expect(page).not_to have_css("h2", text: investigation.documents.first.title)
      expect(page).to have_css("h2", text: "Attachment")
      expect(page).to have_css("p", text: "Only teams added to the case can view this attachment")
    end
  end
end
