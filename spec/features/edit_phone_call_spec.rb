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

    within_fieldset("Who was the call with?") do
      expect(page).to have_field("Name",         with: correspondence.correspondent_name)
      expect(page).to have_field("Phone number", with: correspondence.phone_number)
    end
    expect(page).to have_field("Day",          with: correspondence.correspondence_date.day)
    expect(page).to have_field("Month",        with: correspondence.correspondence_date.month)
    expect(page).to have_field("Year",         with: correspondence.correspondence_date.year)
    expect(page).to have_field("Summary",      with: correspondence.overview)
    expect(page).to have_field("Notes",        with: "\r\n" + correspondence.details, type: "textarea")
    expect(page).to have_link(correspondence.transcript_blob.filename.to_s)

  end
end
