require "rails_helper"

RSpec.describe "Password reset management" do
  let(:user) { create(:user) }
  let!(:reset_token) { Devise.token_generator.generate(User, :reset_password_token) }

  it "allows you to reset your password" do
    allow(Devise.token_generator)
      .to receive(:generate)
            .with(User, :reset_password_token).and_return(reset_token)

    expect(SendResetPasswordInstructions).to receive(:perform_later).with(reset_token.first)

    visit new_user_session_path
    click_link "Forgot your password?"
    fill_in "Email address", with: user.email
    click_on "Send email"

    expect(page).to have_css("p.govuk-body", text: "Click the link in the email to reset your password.")
  end
end
