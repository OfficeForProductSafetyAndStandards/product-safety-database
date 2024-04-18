require "rails_helper"

RSpec.feature "Inviting a user", :with_stubbed_mailer, type: :feature do
  let(:team) { create(:team) }
  let(:user) { create(:user, :activated, team:, has_viewed_introduction: true) }
  let(:email) { Faker::Internet.email }
  let(:name) { "Named User" }

  context "when the user is not a team admin" do
    before do
      sign_in(user)
    end

    it "shows a forbidden error page" do
      visit "/teams/#{team.id}/invitations/new"
      expect_to_be_on_access_denied_page
    end
  end

  context "when the user is a team admin" do
    let(:user) { create(:user, :activated, :team_admin, team:, has_viewed_introduction: true) }

    before do
      sign_in(user)
    end

    context "when there is no other user with that email" do
      before { visit_invite_page_and_submit_email }

      scenario "sends an invitation" do
        expect_to_be_on_team_page(team)
        expect(page).to have_content name
        expect_confirmation_banner("Invite sent to #{email}")
        expect_invitation_email_sent(to: email, inviting_user: user)
      end
    end

    context "when the email is not whitelisted" do
      before do
        set_whitelisting_enabled(true)
        visit_invite_page_and_submit_email
      end

      scenario "shows an error message" do
        expect(page).to have_summary_error("The email address is not recognised. Check you’ve entered it correctly, or email opss.enquiries@businessandtrade.gov.uk to add it to the approved list.")
      end
    end

    context "when there is already a user with that email" do
      let(:existing_user) { create(:user, existing_user_trait, team: existing_user_team) }
      let(:existing_user_team) { user.team }
      let(:email) { existing_user.email }

      before { visit_invite_page_and_submit_email }

      context "when the user is not activated" do
        let(:existing_user_trait) { :inactive }

        scenario "resends the invitation" do
          expect_to_be_on_team_page(team)
          expect_confirmation_banner("Invite sent to #{email}")
          expect_invitation_email_sent(to: email, inviting_user: user)
        end
      end

      context "when the user is activated" do
        let(:existing_user_trait) { :activated }

        scenario "shows an error message" do
          expect(page).to have_summary_error("#{email} is already a member of #{team.name}")
        end
      end

      context "when the user is on another team" do
        let(:existing_user_trait) { :activated }
        let(:existing_user_team) { create(:team) }

        scenario "shows an error message" do
          expect(page).to have_summary_error("You cannot invite this person to join your team because they are already a member of another team. Contact opss.enquiries@businessandtrade.gov.uk if the person’s team needs to be changed.")
        end
      end

      context "when the user is deleted" do
        let(:existing_user_trait) { :deleted }

        scenario "reinvites the user" do
          expect_to_be_on_team_page(team)
          expect_confirmation_banner("Invite sent to #{email}")
          expect_invitation_email_sent(to: email, inviting_user: user)
        end
      end
    end
  end

  context "when the user is a team admin that needs secondary authentication for the invitation", :with_2fa, :with_stubbed_notify do
    let(:user) { create(:user, :activated, :team_admin, team:, has_viewed_introduction: true) }

    before do
      travel_to(4.hours.ago) do
        sign_in(user)
      end
    end

    scenario "sends the invite after after being able to request a second code" do
      visit "/teams/#{team.id}/invitations/new"

      expect_to_be_on_secondary_authentication_page
      click_link "Not received a text message?"

      expect_to_be_on_resend_secondary_authentication_page
      click_button "Resend security code"

      expect_to_be_on_secondary_authentication_page
      fill_in "Enter security code", with: user.reload.direct_otp
      click_button "Continue"

      expect_to_be_on_invite_a_team_member_page
      fill_in "Email address", with: email
      click_button "Send invitation email"

      expect_to_be_on_team_page(team)
      expect_confirmation_banner("Invite sent to #{email}")
      expect_invitation_email_sent(to: email, inviting_user: user)
    end
  end

  context "when invited user has been invited", :with_2fa, :with_stubbed_notify do
    let(:user) { create(:user, :activated, :team_admin, team:, has_viewed_introduction: true) }

    before do
      sign_in(user)
      visit_invite_page_and_submit_email
    end

    context "when user has filled in details and verified phone number but not accepted declaration and signed out" do
      it "does not allow re-inviting" do
        click_link "Your team"
        expect(page).to have_content "Resend invitation to #{email}"

        sign_out

        visit invitation_url

        fill_in_user_info

        click_link "Not received a text message?"

        expect_to_be_on_resend_secondary_authentication_page
        click_button "Resend security code"

        expect_to_be_on_secondary_authentication_page
        fill_in "Enter security code", with: User.find_by(email:).reload.direct_otp
        click_button "Continue"

        sign_out

        sign_in(user)
        click_link "Your team"
        expect(page).not_to have_content "Resend invitation to #{email}"
      end
    end
  end

  def expect_to_be_on_invite_a_team_member_page
    expect(page).to have_css("h1", text: "Invite a team member")
  end

  def visit_invite_page_and_submit_email
    visit "/teams/#{team.id}/invitations/new"
    expect_to_be_on_invite_a_team_member_page

    fill_in "invite-user-to-team-form-email-field", with: email
    fill_in "invite-user-to-team-form-name-field", with: name
    click_button "Send invitation email"
  end

  def expect_invitation_email_sent(to:, inviting_user:)
    notification_email = delivered_emails.last

    expect(notification_email.recipient).to eq(to)
    expect(notification_email.action_name).to eq("invitation_email")
    expect(notification_email.personalization[:inviting_team_member_name]).to eq(inviting_user.name)
  end

  def fill_in_user_info
    fill_in "Full name", with: "Test Person"
    fill_in "Mobile number", with: "07595 295 799"
    fill_in "Password", with: "TestPersonPassword"
    click_button "Continue"
  end

  def invitation_url
    delivered_emails.last.personalization[:invitation_url]
  end
end
