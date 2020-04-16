require "rails_helper"

RSpec.feature "Resetting your password", :with_test_queue_adapter, :with_stubbed_mailer, :with_2fa, type: :feature do
  let(:user)                              { create(:user) }
  let!(:reset_token)                      { stubbed_devise_generated_token }
  let(:edit_user_password_url_with_token) { "http://www.example.com/password/edit?reset_password_token=#{reset_token.first}" }

  scenario "entering an email which does not match an account does not send a notification but shows the confirmation page" do
    user.update!(reset_password_token: reset_token)

    visit "/sign-in"

    click_link "Forgot your password?"

    perform_enqueued_jobs do
      assert_not_requested(:post, "https://api.notifications.service.gov.uk/v2/notifications/email")

      expect(page).to have_css("h1", text: "Reset your password")
      fill_in "Email address", with: Faker::Internet.safe_email
      click_on "Send email"

      expect_to_be_on_check_your_email_page
    end
  end

  scenario "entering an invalid email shows an error" do
    visit "/sign-in"

    click_link "Forgot your password?"

    expect(page).to have_css("h1", text: "Reset your password")

    fill_in "Email address", with: "not_an_email"
    click_on "Send email"

    expect(page).to have_css("h2#error-summary-title", text: "There is a problem")
    expect(page).to have_link("Enter your email address in the correct format, like name@example.com", href: "#email")
  end

  context "with a valid token" do
    scenario "entering a valid password resets your password" do
      request_password_reset

      visit edit_user_password_url_with_token

      # FIXME: just for POC, as 2FA url changed
      # does not changes anything in flow
      #
      # expect_to_be_on_two_factor_authentication_page

      complete_two_factor_authentication_with(last_user_otp(user))

      expect_to_be_on_edit_user_password_page

      expect(page).to have_field("username", type: "email", with: user.email, disabled: true)

      fill_in "Password", with: "a_new_password"
      click_on "Continue"

      expect_to_be_on_password_changed_page

      click_link "Continue"


      # bug or feature? requires second otp for login, as only 2FA was for reset password
      complete_two_factor_authentication_with(last_user_otp(user))
      expect(page).to have_css("h1", text: "Declaration")

      sign_out

      click_on "Sign in to your account"

      fill_in "Email address", with: user.email
      fill_in "Password", with: "a_new_password"
      click_on "Continue"

      expect(page).to have_css("h1", text: "Declaration")
    end

    context "when the password does not fit the criteria" do
      scenario "when the password is too short it shows an error" do
        request_password_reset

        visit edit_user_password_url_with_token

        expect_to_be_on_two_factor_authentication_page

        complete_two_factor_authentication_with(otp_code)

        expect_to_be_on_edit_user_password_page
        puts "filing password"

        fill_in "Password", with: "as"
        click_on "Continue"

        expect(page).to have_css("h2#error-summary-title", text: "There is a problem")
        expect(page).to have_link("Password is too short", href: "#password")

        expect(page).to have_field("username", type: "email", with: user.email, disabled: true)
      end

      scenario "when the password is empty it shows an error" do
        request_password_reset

        visit edit_user_password_url_with_token

        expect_to_be_on_two_factor_authentication_page

        complete_two_factor_authentication_with(otp_code)

        expect_to_be_on_edit_user_password_page

        fill_in "Password", with: ""
        click_on "Continue"

        expect(page).to have_css("h2#error-summary-title", text: "There is a problem")
        expect(page).to have_link("Enter a password", href: "#password")

        expect(page).to have_field("username", type: "email", with: user.email, disabled: true)
      end
    end

    context "when signed in as a different user than the one that requested the password reset" do
      scenario "needs to sign out before being able to reset the password for the original user" do
        # Original user requests password reset
        request_password_reset

        # Second user attempts to use original user reset password link
        other_user = create(:user)
        sign_in(other_user)
        visit edit_user_password_url_with_token

        expect_to_be_on_signed_in_as_another_user_page

        # Second user decides to continue resetting the password for the original user
        click_on "Reset password for #{user.name}"

        expect_to_be_on_two_factor_authentication_page

        # Need to pass 2FA authentication for original user
        complete_two_factor_authentication_with(otp_code)

        # Finally can change the original user password
        expect_to_be_on_edit_user_password_page

        fill_in "Password", with: "a_new_password"
        click_on "Continue"

        expect_to_be_on_password_changed_page
      end
    end
  end

  context "with an expired token" do
    scenario "does not allow you to reset your password" do
      request_password_reset

      travel_to 66.minutes.from_now do
        visit edit_user_password_url_with_token

        expect(page).to have_css("h1", text: "This link has expired")
        expect(page).to have_link("sign in page", href: "/sign-in")
      end
    end
  end

  def request_password_reset
    user.update!(reset_password_token: reset_token)

    visit "/sign-in"

    click_link "Forgot your password?"

    perform_enqueued_jobs do
      body = {
        email_address: user.email,
        template_id: NotifyMailer::TEMPLATES[:reset_password_instruction],
        reference: "Password reset",
        personalisation: {
          name: user.name,
          edit_user_password_url_with_token: edit_user_password_url_with_token
        }
      }

      stub_request(:post, "https://api.notifications.service.gov.uk/v2/notifications/email")
        .with(body: body.to_json).to_return(status: 200, body: {}.to_json, headers: {})

      expect_to_be_on_reset_password_page

      expect(page).to have_css("h1", text: "Reset your password")

      fill_in "Email address", with: user.email
      click_on "Send email"

      expect_to_be_on_check_your_email_page
    end
  end

  def complete_two_factor_authentication_with(security_code)
    fill_in "Enter security code", with: security_code
    click_on "Continue"
  end

  def expect_to_be_on_two_factor_authentication_page
    expect(page.current_path).to match("/secondary_authentications\/new")
  end

  def expect_to_be_on_reset_password_page
    expect(page).to have_current_path("/password/new")
  end

  def expect_to_be_on_signed_in_as_another_user_page
    expect(page).to have_css("h1", text: "You are already signed in to the Product safety database")
  end

  def expect_to_be_on_edit_user_password_page
    expect(page).to have_current_path("/password/edit", ignore_query: true)
  end

  def expect_to_be_on_check_your_email_page
    expect(page).to have_css("h1", text: "Check your email")
  end

  def expect_to_be_on_password_changed_page
    expect(page).to have_current_path("/password-changed")
    expect(page).to have_css("h1", text: "You have changed your password successfully")
  end

  def last_user_otp(user)
    SecondaryAuthentication.where(user_id: user.id).last.direct_otp
  end

  def otp_code
    SecondaryAuthentication.last.direct_otp
  end
end
