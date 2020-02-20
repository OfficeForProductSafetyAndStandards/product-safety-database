require "rails_helper"

RSpec.describe "Password reset management" do
  let(:user) { create(:user) }

  it "allows you to reset your password" do
    visit new_user_session_path

    click_link "Forgot your password?"
    fill_in "Email address", with: user.email
    click_on "Send email"

    expect(page).to have_css("p.govuk-body", text: "Click the link in the email to reset your password.")

    pp ActionMailer::Base.deliveries
  end
end
