require "rails_helper"

describe "Your team", type: :request, with_keycloak_config: true do
  let(:team) { create(:team) }
  let(:user) { create(:user, :activated, teams: [team]) }

  before do
    @another_active_user = create(:user, :activated, email: "active.sameteam@example.com", organisation: user.organisation, teams: [team])
    @another_inactive_user = create(:user, email: "inactive.sameteam@example.com", organisation: user.organisation, teams: [team])
    @another_user_another_team = create(:user, :activated, email: "active.otherteam@example.com", organisation: user.organisation, teams: [create(:team)])

    stub_user_roles(@another_active_user, @another_inactive_user)
    sign_in(as_user: user)
  end

  before { get team_path(team) }

  it "shows the current user" do
    expect(response.body).to have_css(".teams--user .teams--user-email:contains(\"#{user.email}\")")
  end

  it "shows other team members" do
    expect(response.body).to have_css(".teams--user .teams--user-email:contains(\"#{@another_active_user.email}\")")
    expect(response.body).to have_css(".teams--user .teams--user-email:contains(\"#{@another_inactive_user.email}\")")
  end

  it "does not show users from other teams" do
    expect(response.body).not_to have_css(".teams--user .teams--user-email:contains(\"#{@another_user_another_team.email}\")")
  end

  context "re-sending invitation email" do
    context "as a team admin user" do
      let(:user) { create(:user, :activated, :team_admin, teams: [team]) }

      def resend_link_selector(email)
        "a[href=\"#{resend_invitation_team_path(team)}?email_address=#{CGI.escape(email)}\"]"
      end

      it "displays the link for inactive users" do
        expect(response.body).to have_css(resend_link_selector(@another_inactive_user.email))
      end

      it "does not display the link for active users" do
        expect(response.body).not_to have_css(resend_link_selector(@another_active_user.email))
      end
    end

    context "as a normal user" do
      let(:user) { create(:user, :activated, :psd_user, teams: [team]) }

      it "does not display the link for any users" do
        expect(response.body).not_to have_css("a[href*=\"#{resend_invitation_team_path(team)}\"]")
      end
    end
  end
end
