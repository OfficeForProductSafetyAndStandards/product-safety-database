require "rails_helper"

RSpec.feature "Your team page", :with_stubbed_elasticsearch, :with_stubbed_keycloak_config do
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

    context "as a normal user" do
      let(:user) { create(:user, :activated, :psd_user, teams: [team]) }

      scenario "does not display the link for any users" do
        expect(page).not_to have_css("a[href*=\"#{resend_invitation_team_path(team)}\"]")
      end
    end
  end
end
