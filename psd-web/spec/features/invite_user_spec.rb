require "rails_helper"

RSpec.feature "Inviting a user", :with_stubbed_mailer, :with_stubbed_elasticsearch, type: :feature do
  let(:team) { create(:team) }
  let(:user) { create(:user, :activated, :team_admin, teams: [team], has_viewed_introduction: true) }

  context "when there is already a user with that email" do
    before do
      sign_in(user)
    end

    scenario "shows an error message" do
      visit invite_to_team_url(team)
      expect_to_be_on_invite_a_team_member_page

      fill_in "new_user_email_address", with: user.email
      click_button "Send invitation email"
      expect(page).to have_css(".govuk-error-summary__list", text: "You cannot invite this person to join your team because they are already a member of another team from a different organisation.")
    end
  end

  context "when the email corresponds to a deleted user" do
    let(:deleted_user) { create(:user, :deleted) }

    before do
      sign_in(user)
    end

    scenario "shows an error message" do
      visit invite_to_team_url(team)
      expect_to_be_on_invite_a_team_member_page

      fill_in "new_user_email_address", with: deleted_user.email
      click_button "Send invitation email"
      expect(page).to have_css(".govuk-error-summary__list", text: "Email address belongs to a user that has been deleted. Email OPSS if you would like their account restored.")
    end
  end

  context "when 2fa expires", :with_2fa, :with_stubbed_notify do
    scenario "user invites with correct secondary authentication code after requesting a second code" do
      allow(Rails.application.config).to receive(:whitelisted_emails).and_return(
        "email_domains" => ["example.com"]
      )
      travel_to(4.hours.ago) do
        sign_in(user)
      end

      visit invite_to_team_url(team)

      expect_to_be_on_secondary_authentication_page
      click_link "Not received a text message?"

      expect_to_be_on_resend_secondary_authentication_page
      click_button "Resend security code"

      expect_to_be_on_secondary_authentication_page
      fill_in "Enter security code", with: user.reload.direct_otp
      click_button "Continue"

      expect_to_be_on_invite_a_team_member_page
      fill_in "new_user_email_address", with: Faker::Internet.email(domain: "example.com")
      click_button "Send invitation email"
    end
  end
end
