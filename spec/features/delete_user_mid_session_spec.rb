require "rails_helper"

RSpec.feature "Deleting a user while they are in an active session", :with_stubbed_antivirus, :with_stubbed_mailer, type: :feature do
  let(:user) { create(:user, :activated, has_viewed_introduction: true) }

  scenario "Deleting a signed in user" do
    sign_in user
    visit "/cases/"

    expect(page).to have_link "Your account"
    expect(page).to have_link "Sign out"

    DeleteUser.call!(user:)

    click_link "Create a notification"

    expect(page).not_to have_link "Your account"
    expect(page).not_to have_link "Sign out"
    expect(page).to have_link "Sign in"
  end
end
