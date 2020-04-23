require "rails_helper"

RSpec.feature "Adding an activity to a case", :with_stubbed_elasticsearch, :with_stubbed_antivirus, :with_stubbed_mailer, type: :feature do

  let(:user) { create(:user, :activated) }
  let(:investigation) { create(:investigation) }

  scenario "Picking an activity type" do
    sign_in user

    visit "/cases/#{investigation.pretty_id}"

    click_link "Add activity"

    expect(page).to have_content("New activity")

    click_button "Continue"

    expect(page).to have_content("Activity type must not be empty")
  end
end
