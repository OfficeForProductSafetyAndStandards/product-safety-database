require "rails_helper"

RSpec.feature "Manage Images", :with_stubbed_elasticsearch, :with_stubbed_antivirus, :with_stubbed_mailer do
  let(:user)          { create(:user, :activated, has_viewed_introduction: true) }
  let(:investigation) { create(:investigation, owner: user.team) }

  include_context "with all types of supporting information"

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
  end
end
