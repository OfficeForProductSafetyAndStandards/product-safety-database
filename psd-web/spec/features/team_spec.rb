require "rails_helper"

RSpec.feature "Your team page", :with_stubbed_keycloak_config, :with_stubbed_mailer, :with_stubbed_elasticsearch do
  let(:team) { create(:team) }
  let(:user) { create(:user, :activated, teams: [team]) }

  let!(:another_active_user) { create(:user, :activated, email: "active.sameteam@example.com", organisation: user.organisation, teams: [team]) }
  let!(:another_inactive_user) { create(:user, email: "inactive.sameteam@example.com", organisation: user.organisation, teams: [team]) }
  let!(:another_user_another_team) { create(:user, :activated, email: "active.otherteam@example.com", organisation: user.organisation, teams: [create(:team)]) }

  before do
    sign_in(as_user: user)
    visit team_path(team)
  end

  scenario "only shows team members, including the current user" do
    expect(page).to have_css(".teams--user .teams--user-email:contains(\"#{user.email}\")")
    expect(page).to have_css(".teams--user .teams--user-email:contains(\"#{another_active_user.email}\")")
    expect(page).to have_css(".teams--user .teams--user-email:contains(\"#{another_inactive_user.email}\")")
    expect(page).not_to have_css(".teams--user .teams--user-email:contains(\"#{another_user_another_team.email}\")")
  end

  context "re-sending invitation email" do
    context "as a team admin user" do
      let(:user) { create(:user, :activated, :team_admin, teams: [team]) }

      def resend_link_selector(email)
        "a[href=\"#{resend_invitation_team_path(team)}?email_address=#{CGI.escape(email)}\"]"
      end

      scenario "only displays the link for inactive users" do
        expect(page).to have_css(resend_link_selector(another_inactive_user.email))
        expect(page).not_to have_css(resend_link_selector(another_active_user.email))
      end
    end
  end


  context "As a team admin user" do
    let(:email_whitelist_enabled) { false }
    context "when I invite a new user" do
      let(:user) { create(:user, :activated, :team_admin, teams: [team]) }
      let(:invite_email) { Faker::Internet.safe_email }
      let(:keycloak_get_user_response) { { id: SecureRandom.uuid } }

      before do
        allow(KeycloakClient.instance).to receive(:create_user).with(invite_email)
        allow(KeycloakClient.instance).to receive(:get_user).with(invite_email).and_return(keycloak_get_user_response)
        allow(Rails.application.config).to receive(:email_whitelist_enabled).and_return(email_whitelist_enabled)
      end
      #Need to cover this scenario later when we integrate new auth devise

      # scenario "I should be able to invite a team member" do
      #   click_link "Invite a team member"
      #   fill_in "new_user_email_address", with: invite_email
      #   click_button "Send invitation email"
      #   save_and_open_page
      #   expect(page).to have_css(".hmcts-banner__message", text: "Invite sent to #{invite_email}")
      # end
    end

    context "when I invite an existing user" do
      let(:user) { create(:user, :activated, :team_admin, teams: [team]) }

      scenario ",I should see an error message" do
        click_link "Invite a team member"
        fill_in "new_user_email_address", with: user.email.to_s
        expect(page).to have_css(".govuk-error-summary__list", text: "You cannot invite this person to join your team because they are already a member of another team from a different organisation.")
      end
    end
  end

  context "as a normal user" do
    let(:user) { create(:user, :activated, :psd_user, teams: [team]) }

    scenario "does not display the link for any users" do
      expect(page).not_to have_css("a[href*=\"#{resend_invitation_team_path(team)}\"]")
    end

    scenario "does not display the invite a team member link" do
      expect(page).not_to have_css("govuk-button", text: "Invite a team member")
    end
  end
end
