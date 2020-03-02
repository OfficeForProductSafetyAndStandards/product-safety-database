require "rails_helper"

RSpec.feature "Signing in", :with_elasticsearch, :with_stubbed_mailer, type: :feature do
  include ActiveSupport::Testing::TimeHelpers

  let(:investigation) { create(:project) }
  let(:user) { create(:user, :activated, has_viewed_introduction: true) }

  it "allows user to sign in" do
    visit root_path
    click_on "Sign in to your account"

    fill_in "Email address", with: user.email
    fill_in "Password", with: "2538fhdkvuULE36f"
    click_on "Continue"

    expect(page).to have_link("Sign out", href: destroy_user_session_path)
  end

  context "when signed in" do
    it "times you out in due time" do
      visit investigation_path(investigation)
      expect(page).to_not have_css("h2#error-summary-title", text: "You need to sign in or sign up before continuing.")

      travel_to 24.hours.from_now do
        visit investigation_path(investigation)
        expect(page).to_not have_css("h2#error-summary-title", text: "Your session expired. Please sign in again to continue.")
      end
    end
  end

  context "credentials entered incorrectly" do
    it "highlights email field" do
      visit root_path
      click_on "Sign in to your account"

      fill_in "Email address", with: user.email
      fill_in "Password", with: "passworD"
      click_on "Continue"

      expect(page).to have_css("h2#error-summary-title", text: "There is a problem")
      expect(page).to have_link("Enter correct email address and password", href: "#email")
      expect(page).to have_css("span#email-error", text: "Error: Enter correct email address and password")
      expect(page).to have_css("span#password-error", text: "")
    end
  end
end
