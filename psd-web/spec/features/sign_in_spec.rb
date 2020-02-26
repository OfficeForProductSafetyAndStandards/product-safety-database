require "rails_helper"

RSpec.feature "Signing in", :with_elasticsearch, :with_stubbed_mailer do
  include ActiveSupport::Testing::TimeHelpers
  let(:investigation) { create(:project) }
  let(:user) { create(:user, :activated, has_viewed_introduction: true) }

  it "allows user to sign in" do
    visit root_path
    click_on "Sign in to your account"

    fill_in "Email address", with: user.email
    fill_in "Password", with: "password"
    click_on "Continue"

    expect(page).to have_link("Sign out", href: destroy_user_session_path)
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
    context "when email address is not in correct format" do
      scenario "shows an error message" do
        visit root_path
        click_on "Sign in to your account"
        

        fill_in "Email address", with: "test.email"
        fill_in "Password", with: "password "
        click_on "Continue"
        

        expect(page).to have_css(".govuk-error-summary__list", text: "Enter your email address in the correct format, like name@example.com")
        expect(page).to have_css(".govuk-error-message", text: "Enter your email address in the correct format, like name@example.com")
      end
    end

    context "when email and password fields left empty" do
      scenario "shows error messages" do
        visit root_path
        click_on "Sign in to your account"

        fill_in "Email address", with: " "
        fill_in "Password", with: " "
        click_on "Continue"

        expect(page).to have_css(".govuk-error-message", text: "Enter your email address")
        expect(page).to have_css(".govuk-error-message", text: "Enter your password")
      end
    end

    context "when password field is left empty" do
      scenario "shows an error messages" do
        visit root_path
        click_on "Sign in to your account"

        fill_in "Email address", with: user.email
        fill_in "Password", with: " "
        click_on "Continue"

        expect(page).to have_css(".govuk-error-message", text: "Enter your password")
        expect(page).to have_css(".govuk-error-summary__list", text: "Enter your password")
      end
    end
  end
end
