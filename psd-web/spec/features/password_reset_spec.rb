require "rails_helper"

RSpec.describe "Resetting your password", :with_test_queue_adpater do
  let(:user)                         { create(:user) }
  let!(:reset_token)                 { Devise.token_generator.generate(User, :reset_password_token) }
  let(:edit_user_password_url_token) { edit_user_password_url(reset_password_token: reset_token.first) }


  def request_password_reset
    allow(Devise.token_generator)
      .to receive(:generate)
            .with(User, :reset_password_token).and_return(reset_token)
    _raw, enc = reset_token
    user.update!(reset_password_token: enc)

    visit "/sign-in"

    click_link "Forgot your password?"

    perform_enqueued_jobs do
      body = {
        email_address: user.email,
        template_id: NotifyMailer::TEMPLATES[:reset_password_instruction],
        reference: "Password reset",
        personalisation: {
          name: user.name,
          edit_user_password_url_token: edit_user_password_url_token
        }
      }

      stub_request(:post, "https://api.notifications.service.gov.uk/v2/notifications/email")
        .with(body: body.to_json).to_return(status: 200, body: {}.to_json, headers: {})

      expect(page).to have_css("h1", text: "Reset your password")
      fill_in "Email address", with: user.email
      click_on "Send email"
    end
  end

  context "when entering an invalid email" do
    it "does not allow you to reset you pasword" do
      visit "/sign-in"

      click_link "Forgot your password?"

      expect(page).to have_css("h1", text: "Reset your password")

      fill_in "Email address", with: "not_an_email"
      click_on "Send email"

      expect(page).to have_css("h2#error-summary-title", text: "There is a problem")
      expect(page).to have_link("Enter your email address in the correct format, like name@example.com", href: "#email")
    end
  end

  context "with a valid token" do
    it "does not allow you to reset you pasword" do
      send_reset_password
      expect(page).to have_css("p.govuk-body", text: "Click the link in the email to reset your password.")

      visit edit_user_password_url_token

      fill_in "Password", with: "a_new_password"
      click_on "Continue"

      expect(page).to have_css("h1", text: "Declaration")

      sign_out

      click_on "Sign in to your account"

      fill_in "Email address", with: user.email
      fill_in "Password", with: "a_new_password"
      click_on "Continue"

      expect(page).to have_css("h1", text: "Declaration")
    end

    context "when the password does not fit the criteria" do
      context "when the password is too short" do
        let(:password) { "as" }
        it "does not allow you to reset your password" do
          send_reset_password

          visit edit_user_password_url_token

          fill_in "Password", with: password
          click_on "Continue"

          expect(page).to have_css("h2#error-summary-title", text: "There is a problem")
          expect(page).to have_link("Password is too short (minimum is 8 characters)", href: "#password")
        end
      end

      context "when the password is too short" do
        let(:password) { "" }

        it "does not allow you to reset your password" do
          send_reset_password

          visit edit_user_password_url_token

          fill_in "Password", with: password
          click_on "Continue"

          expect(page).to have_css("h2#error-summary-title", text: "There is a problem")
          expect(page).to have_link("Password cannot be blank", href: "#password")
        end
      end
    end
  end

  context "with and invalid token" do
    it "does not allow you to reset your password" do
      send_reset_password

      travel_to 66.minutes.from_now do
        visit edit_user_password_url_token

        fill_in "Password", with: "password"
        click_on "Continue"

        expect(page).to have_css("h1", text: "This link has expired")
        expect(page).to have_link("sign in page", href: new_user_session_path)
      end
    end
  end
end
