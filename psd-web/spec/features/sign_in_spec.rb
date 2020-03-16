require "rails_helper"

RSpec.feature "Signing in", :with_elasticsearch, :with_stubbed_mailer, :with_stubbed_notify, type: :feature do
  include ActiveSupport::Testing::TimeHelpers

  let(:investigation) { create(:project) }
  let(:user) { create(:user, :activated, has_viewed_introduction: true) }

  def fill_in_credentials
    visit "/sign-in"

    fill_in "Email address", with: user.email
    fill_in "Password", with: "2538fhdkvuULE36f"
    click_on "Continue"
  end

  context "when succeeeding signin in", :with_2fa do
    context "when in two factor authentication page" do
      it "allows user to sign in with correct two factor authentication code" do
        fill_in_credentials

        expect(page).to have_css("h1", text: "Check your phone")

        fill_in "Enter security code", with: user.reload.direct_otp
        click_on "Continue"

        expect(page).to have_css("h2", text: "Your cases")
        expect(page).to have_link("Sign out", href: destroy_user_session_path)
      end

      it "allows user to sign out and be sent to the homepage" do
        fill_in_credentials

        expect(page).to have_css("h1", text: "Check your phone")

        within(".psd-header__secondary-navigation") do
          click_link("Sign out")
        end

        expect(page).to have_css("h1", text: "Product safety database")
        expect(page).to have_link("Sign in to your account")
      end

      it "don't allow the user to sign in with a wrong two factor authentication code" do
        fill_in_credentials

        expect(page).to have_css("h1", text: "Check your phone")

        fill_in "Enter security code", with: user.reload.direct_otp.reverse
        click_on "Continue"

        expect(page).to have_css("h1", text: "Check your phone")
        expect(page).to have_css("h2#error-summary-title", text: "There is a problem")
        expect(page).to have_css("#otp_code-error", text: "Error: Incorrect security code")
      end
    end
  end

  context "when signed in" do
    it "times you out in due time" do
      visit investigation_path(investigation)
      expect(page).not_to have_css("h2#error-summary-title", text: "You need to sign in or sign up before continuing.")

      travel_to 24.hours.from_now do
        visit investigation_path(investigation)
        expect(page).not_to have_css("h2#error-summary-title", text: "Your session expired. Please sign in again to continue.")
      end
    end
  end

  context "with credentials entered incorrectly" do
    it "highlights email field" do
      visit "/sign-in"

      fill_in "Email address", with: user.email
      fill_in "Password", with: "passworD"
      click_on "Continue"

      expect(page).to have_css("h2#error-summary-title", text: "There is a problem")
      expect(page).to have_link("Enter correct email address and password", href: "#email")
      expect(page).to have_css("span#email-error", text: "Error: Enter correct email address and password")
      expect(page).to have_css("span#password-error", text: "")
    end

    context "when email address is not in correct format" do
      scenario "shows an error message" do
        visit "/sign-in"

        fill_in "Email address", with: "test.email"
        fill_in "Password", with: "password "
        click_on "Continue"


        expect(page).to have_css(".govuk-error-summary__list", text: "Enter your email address in the correct format, like name@example.com")
        expect(page).to have_css(".govuk-error-message", text: "Enter your email address in the correct format, like name@example.com")
      end
    end

    context "when email and password fields left empty" do
      scenario "shows error messages" do
        visit "/sign-in"

        fill_in "Email address", with: " "
        fill_in "Password", with: " "
        click_on "Continue"

        expect(page).to have_css(".govuk-error-message", text: "Enter your email address")
        expect(page).to have_css(".govuk-error-message", text: "Enter your password")
      end
    end


    context "when password field is left empty" do
      scenario "shows an error messages" do
        visit "/sign-in"


        fill_in "Email address", with: user.email
        fill_in "Password", with: " "
        click_on "Continue"

        expect(page).to have_css(".govuk-error-message", text: "Enter your password")
        expect(page).to have_css(".govuk-error-summary__list", text: "Enter your password")
      end
    end
  end
end
