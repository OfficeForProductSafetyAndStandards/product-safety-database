require "rails_helper"

RSpec.describe "Password reset management", :with_test_queue_adpater do
  let(:user)                         { create(:user) }
  let!(:reset_token)                 { Devise.token_generator.generate(User, :reset_password_token) }
  let(:edit_user_password_url_token) { edit_user_password_url(reset_password_token: reset_token.first) }

  it "allows you to reset your password" do
    allow(Devise.token_generator)
      .to receive(:generate)
            .with(User, :reset_password_token).and_return(reset_token)
    raw, enc = reset_token
    user.update!(reset_password_token: enc)

    visit new_user_session_path

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

      fill_in "Email address", with: user.email
      click_on "Send email"
    end

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
end
