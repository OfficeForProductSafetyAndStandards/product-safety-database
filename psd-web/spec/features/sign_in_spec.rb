require "rails_helper"

RSpec.feature "Signing in", :with_elasticsearch, :with_stubbed_mailer do
  let(:investigation) { create(:project) }
  let(:user) { create(:user, :activated, has_viewed_introduction: true) }

  def fill_in_credentials
    visit root_path
    click_on "Sign in to your account"

    stub_request(:post, "https://api.notifications.service.gov.uk/v2/notifications/sms").and_return(body: {}.to_json)

    fill_in "Email address", with: user.email
    fill_in "Password", with: "password"
    click_on "Continue"
  end

  context "when succeeeding signin in" do
    context "when succeeding two factor authentication" do

      it "allows user to sign in" do
        fill_in_credentials

        expect(page).to have_css("h1", text: "Check your phone")

        fill_in "Enter security code", with: user.reload.direct_otp
        click_on "Continue"

        expect(page).to have_css("h2", text: "Your cases")
        expect(page).to have_link("Sign out", href: destroy_user_session_path)
      end
    end

    context "when failing two factor authentication" do
      it "one can not fail more than 3 times" do
        fill_in_credentials

        expect(page).to have_css("h1", text: "Check your phone")

        2.times do
          fill_in "Enter security code", with: user.reload.direct_otp.chars.shuffle.join
          click_on "Continue"

          expect(page).to have_css("h2#error-summary-title", text: "There is a problem")
          expect(page).to have_link("Attempt failed.", href: "#direct_otp")
        end

        fill_in "Enter security code", with: user.reload.direct_otp.chars.shuffle.join
        click_on "Continue"

        expect(page).to have_css("h2", text: "Access completely denied as you have reached your attempts limit = 3")
      end
    end
  end

  context "when failing to sign in" do
    it "allows to sign in and times you out in due time" do
      visit investigation_path(investigation)
      expect(page).to_not have_css("h2#error-summary-title", text: "You need to sign in or sign up before continuing.")

      travel_to 24.hours.from_now do
        visit investigation_path(investigation)
        expect(page).to_not have_css("h2#error-summary-title", text: "Your session expired. Please sign in again to continue.")
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
end
