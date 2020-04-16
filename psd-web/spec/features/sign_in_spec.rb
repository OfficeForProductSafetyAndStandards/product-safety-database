require "rails_helper"

RSpec.feature "Signing in", :with_elasticsearch, :with_stubbed_mailer, :with_stubbed_notify, :with_2fa, type: :feature do
  include ActiveSupport::Testing::TimeHelpers

  let(:investigation) { create(:project) }
  let(:user) { create(:user, :activated, has_viewed_introduction: true) }

  def fill_in_credentials(password_override: nil)
    fill_in "Email address", with: user.email
    if password_override
      fill_in "Password", with: password_override
    else
      fill_in "Password", with: user.password
    end
    click_on "Continue"
  end

  def expect_incorrect_email_or_password
    expect(page).to have_css("h2#error-summary-title", text: "There is a problem")
    expect(page).to have_link("Enter correct email address and password", href: "#email")
    expect(page).to have_css("span#email-error", text: "Error: Enter correct email address and password")
    expect(page).to have_css("span#password-error", text: "")

    expect(page).not_to have_link("Cases")
  end

  scenario "user signs in with correct two factor authentication code" do
    visit "/sign-in"
    fill_in_credentials

    expect(page).to have_css("h1", text: "Check your phone")

    fill_in "Enter security code", with: " #{user.reload.direct_otp} "
    click_on "Continue"

    expect(page).to have_css("h2", text: "Your cases")
    expect(page).to have_link("Sign out", href: destroy_user_session_path)
  end

  scenario "user signs out when required to fill two factor authentication code" do
    visit "/sign-in"
    fill_in_credentials

    expect(page).to have_css("h1", text: "Check your phone")

    within(".psd-header__secondary-navigation") do
      click_link("Sign out")
    end

    expect(page).to have_css("h1", text: "Product safety database")
    expect(page).to have_link("Sign in to your account")
  end

  scenario "user attempts to sign in with wrong two factor authentication code" do
    visit "/sign-in"
    fill_in_credentials

    expect(page).to have_css("h1", text: "Check your phone")

    fill_in "Enter security code", with: user.reload.direct_otp.reverse
    click_on "Continue"

    expect(page).to have_css("h1", text: "Check your phone")
    expect(page).to have_css("h2#error-summary-title", text: "There is a problem")
    expect(page).to have_css("#otp_code-error", text: "Error: Incorrect security code")
  end

  context "when using wrong credentials over and over again" do
    let(:unlock_email) { delivered_emails.last }
    let(:unlock_path) { unlock_email.personalization_path(:unlock_user_url_token) }

    scenario "user gets locked and uses the unlock link received by email" do
      visit "/sign-in"
      fill_in_credentials
      fill_in "Enter security code", with: user.reload.direct_otp
      click_on "Continue"
      expect(page).to have_link("Sign out", href: destroy_user_session_path)
      within(".psd-header__secondary-navigation") do
        click_link("Sign out")
      end

      Devise.maximum_attempts.times do
        visit "/sign-in"
        fill_in_credentials(password_override: "XXX")
      end

      expect(page).to have_css("p", text: "We’ve locked this account to protect its security.")

      visit unlock_path

      expect(page).to have_css("h1", text: "Check your phone")

      fill_in "Enter security code", with: user.reload.direct_otp
      click_on "Continue"

      fill_in_credentials

      expect(page).to have_css("h2", text: "Your cases")
      expect(page).to have_link("Sign out")
    end

    scenario "user tries to use unlock link when logged in as different user" do
      user2 = create(:user, :activated, has_viewed_introduction: true)
      user2.lock_access!

      visit "/sign-in"
      fill_in_credentials
      fill_in "Enter security code", with: user.reload.direct_otp
      click_on "Continue"

      expect(page).to have_css("h2", text: "Your cases")

      visit unlock_path
      expect(page).to have_css("h1", text: "Check your phone")
    end

    scenario "user follows an invalid unlock link" do
      visit "/unlock?unlock_token=wrong-token"
      expect(page).to have_css("h1", text: "Invalid link")
      expect(page.status_code).to eq(404)
    end

    scenario "locked user receives email with reset password link" do
      Devise.maximum_attempts.times do
        visit "/sign-in"
        fill_in_credentials(password_override: "XXX")
      end

      expect(page).to have_css("p", text: "We’ve locked this account to protect its security.")

      unlock_email = delivered_emails.last
      visit unlock_email.personalization_path(:edit_user_password_url_token)

      expect(page).to have_css("h1", text: "Check your phone")

      fill_in "Enter security code", with: user.reload.direct_otp
      click_on "Continue"

      expect(page).to have_css("h1", text: "Create a new password")
    end
  end

  scenario "user session expires" do
    visit investigation_path(investigation)
    expect(page).not_to have_css("h2#error-summary-title", text: "You need to sign in or sign up before continuing.")

    travel_to 24.hours.from_now do
      visit investigation_path(investigation)
      expect(page).not_to have_css("h2#error-summary-title", text: "Your session expired. Please sign in again to continue.")
    end
  end

  scenario "user tries to sign in without having verified its mobile number on registration" do
    user.update_column(:mobile_number_verified, false)

    visit "/sign-in"

    fill_in_credentials
    expect_incorrect_email_or_password
    expect(notify_stub).not_to have_received(:send_sms)
  end

  scenario "user tries to sign in with email address that does not belong to any user" do
    visit "/sign-in"

    fill_in "Email address", with: "notarealuser@example.com"
    fill_in "Password", with: "notarealpassword"
    click_on "Continue"

    expect_incorrect_email_or_password
  end

  scenario "user introduces wrong password" do
    visit "/sign-in"

    fill_in "Email address", with: user.email
    fill_in "Password", with: "passworD"
    click_on "Continue"

    expect_incorrect_email_or_password
  end

  scenario "user introduces email address with incorrect format" do
    visit "/sign-in"

    fill_in "Email address", with: "test.email"
    fill_in "Password", with: "password "
    click_on "Continue"


    expect(page).to have_css(".govuk-error-summary__list", text: "Enter your email address in the correct format, like name@example.com")
    expect(page).to have_css(".govuk-error-message", text: "Enter your email address in the correct format, like name@example.com")
  end

  scenario "user leaves email and password fields empty" do
    visit "/sign-in"

    fill_in "Email address", with: " "
    fill_in "Password", with: " "
    click_on "Continue"

    expect(page).to have_css(".govuk-error-message", text: "Enter your email address")
    expect(page).to have_css(".govuk-error-message", text: "Enter your password")
  end

  scenario "user leaves password field empty" do
    visit "/sign-in"

    fill_in "Email address", with: user.email
    fill_in "Password", with: " "
    click_on "Continue"

    expect(page).to have_css(".govuk-error-message", text: "Enter your password")
    expect(page).to have_css(".govuk-error-summary__list", text: "Enter your password")
  end
end
