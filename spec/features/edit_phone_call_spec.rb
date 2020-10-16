require "rails_helper"

RSpec.feature "Edit a phone call correspondence", :with_stubbed_elasticsearch, :with_stubbed_antivirus, :with_stubbed_mailer, type: :feature do
  include_context "with phone call correspondence setup"

  let!(:correspondence) { AddPhoneCallToCase.call!(investigation: investigation, user: user, **params).correspondence.decorate }

  before do
    sign_in investigation.owner_user
  end

  it "allows to edit the phone call record" do
    visit "/cases/#{investigation.pretty_id}/phone-calls/#{correspondence.id}"

    click_on "Edit phone call"

    expect(page).to have_title("Edit phone call: #{correspondence.title}")


  end
end
