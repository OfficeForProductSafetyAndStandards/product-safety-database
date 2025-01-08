require "rails_helper"

RSpec.feature "Signing in", :with_2fa, :with_opensearch, :with_stubbed_mailer, type: :feature do
  include ActiveSupport::Testing::TimeHelpers

  let(:investigation) { create(:project) }
  let(:user) { create(:user, :activated, has_viewed_introduction: true) }
  let(:notify_stub) { instance_double(Notifications::Client) }
  let(:sms_calls) { [] }

  def stub_sms_service
    allow(notify_stub).to receive(:send_sms)

    allow(SendSMS).to receive(:new).and_return(
      instance_double(SendSMS).tap do |sms_service|
        allow(sms_service).to receive(:otp_code) do |mobile_number:, code:|
          sms_calls << {
            phone_number: mobile_number,
            template_id: SendSMS::TEMPLATES[:otp_code],
            personalisation: { code: }
          }
          notify_stub.send_sms(sms_calls.last)
        end
      end
    )

    allow(Notifications::Client).to receive(:new).and_return(notify_stub)

    notify_stub
  end

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
    expect(page).to have_text("Enter correct email address and password")
    expect(page).not_to have_link("Notifications")
  end

  def expect_user_to_have_received_sms_code(code)
    matching_call = sms_calls.find { |call| call[:personalisation][:code] == code.to_s }
    expect(matching_call).to be_present, "Expected to find SMS with code #{code} in calls: #{sms_calls.inspect}"

    expect(matching_call[:phone_number]).to eq(user.mobile_number)
    expect(matching_call[:template_id]).to eq(SendSMS::TEMPLATES[:otp_code])
  end

  def otp_code
    user.reload.direct_otp
  end

  before do
    stub_sms_service
  end

  scenario "user signs in with correct two factor authentication code" do
    visit "/sign-in"
    fill_in_credentials

    expect(page).to have_css("h1", text: "Check your phone")

    fill_in "Enter security code", with: "#{otp_code} "
    click_on "Continue"

    expect(page).to have_css("h2", text: "How to create a product safety notification")
    expect(page).to have_link("Sign out", href: destroy_user_session_path)
  end

  scenario "user signs out when required to fill two factor authentication code" do
    visit "/sign-in"
    fill_in_credentials

    expect(page).to have_css("h1", text: "Check your phone")

    within(".psd-header__secondary-navigation-list") do
      click_link("Sign out")
    end

    expect(page).to have_css("h1", text: "Product Safety Database")
    expect(page).to have_link("Sign in")
  end

  scenario "user attempts to sign in with wrong two factor authentication code" do
    allow(SecureRandom).to receive(:random_number).and_return(12_345)

    visit "/sign-in"
    fill_in_credentials

    expect(page).to have_css("h1", text: "Check your phone")

    fill_in "Enter security code", with: "54321"
    click_on "Continue"

    expect(page).to have_css("h1", text: "Check your phone")
    expect(page).to have_text("Incorrect security code")
  end

  scenario "user signs in with correct secondary authentication code after requesting a second code" do
    visit "/sign-in"
    fill_in_credentials

    first_code = user.reload.direct_otp
    expect_user_to_have_received_sms_code(first_code)

    click_link "Not received a text message?"
    click_button "Resend security code"

    second_code = user.reload.direct_otp
    expect_user_to_have_received_sms_code(second_code)

    fill_in "Enter security code", with: second_code
    click_button "Continue"

    expect(page).to have_css("h2", text: "How to create a product safety notification")
    expect(page).to have_link("Sign out", href: destroy_user_session_path)
  end

  context "when using wrong credentials over and over again" do
    let(:unlock_email) { delivered_emails.last }
    let(:unlock_path) { unlock_email.personalization_path(:unlock_user_url_token) }

    scenario "user gets locked and uses the unlock link received by email" do
      Devise.maximum_attempts.times do
        visit "/sign-in"
        fill_in_credentials(password_override: "XXX")
      end

      expect(page).to have_content("We’ve locked this account to protect its security.")

      visit unlock_path

      expect(page).to have_css("h1", text: "Check your phone")

      fill_in "Enter security code", with: otp_code
      click_on "Continue"

      fill_in_credentials

      expect(page).to have_css("h2", text: "How to create a product safety notification")
      expect(page).to have_link("Sign out")
    end

    scenario "user tries to use unlock link when logged in as different user" do
      user2 = create(:user, :activated, has_viewed_introduction: true)
      user2.lock_access!

      visit "/sign-in"
      fill_in_credentials
      fill_in "Enter security code", with: otp_code
      click_on "Continue"

      expect(page).to have_css("h2", text: "How to create a product safety notification")

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

      expect(page).to have_content("We’ve locked this account to protect its security.")

      unlock_email = delivered_emails.last
      visit unlock_email.personalization_path(:edit_user_password_url_token)

      expect(page).to have_css("h1", text: "Check your phone")

      fill_in "Enter security code", with: otp_code
      click_on "Continue"

      expect(page).to have_css("h1", text: "Create a new password")
    end
  end

  scenario "user session expires" do
    visit investigation_path(investigation)
    expect(page).not_to have_text("You need to sign in or sign up before continuing.")

    travel_to 24.hours.from_now do
      visit investigation_path(investigation)
      expect(page).not_to have_text("Your session expired. Please sign in again to continue.")
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

  context "when trying to sign in credentials corresponding to a deleted user" do
    let(:user) { create(:user, :deleted) }

    scenario "user gets an error message" do
      visit "/sign-in"
      fill_in_credentials

      expect_incorrect_email_or_password
    end
  end

  scenario "it does not show a breadcrumb on the login page" do
    visit "/sign-in"
    expect(page).not_to have_css(".govuk-breadcrumbs__link")
  end

  scenario "user introduces email address with incorrect format" do
    visit "/sign-in"

    fill_in "Email address", with: "test.email"
    fill_in "Password", with: "password "
    click_on "Continue"

    expect(page).to have_text("Enter your email address in the correct format, like name@example.com")
  end

  scenario "user leaves email and password fields empty" do
    visit "/sign-in"

    fill_in "Email address", with: " "
    fill_in "Password", with: " "
    click_on "Continue"

    expect(page).to have_text("Enter your email address")
    expect(page).to have_text("Enter your password")
  end

  scenario "user leaves password field empty" do
    visit "/sign-in"

    fill_in "Email address", with: user.email
    fill_in "Password", with: " "
    click_on "Continue"

    expect(page).to have_text("Enter your password")
  end
end
