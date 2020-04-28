require "rails_helper"

RSpec.feature "Your team page", :with_stubbed_mailer, :with_stubbed_elasticsearch, type: :feature do
  let(:team) { create(:team) }
  let(:user) { create(:user, :activated, :psd_user, teams: [team], has_viewed_introduction: true) }

  let!(:another_active_user) { create(:user, :activated, email: "active.sameteam@example.com", organisation: user.organisation, teams: [team], has_viewed_introduction: true) }
  let!(:another_inactive_user) { create(:user, email: "inactive.sameteam@example.com", invited_at: 1.year.ago, organisation: user.organisation, teams: [team]) }
  let!(:another_user_another_team) { create(:user, :activated, email: "active.otherteam@example.com", organisation: user.organisation, teams: [create(:team)]) }

  before do
    sign_in(user)
    visit team_path(team)
    expect_to_be_on_team_page
  end

  context "when the user is not a team admin" do
    scenario "displays the current user but not users belonging to other teams and does not display the resend invite link for any users or the invite a team member link" do
      expect(page).to have_user(user)
      expect(page).to have_user(another_active_user)
      expect(page).to have_user(another_inactive_user)
      expect(page).not_to have_user(another_user_another_team)

      expect(page).not_to have_resend_invite_link_for(another_inactive_user)
      expect(page).not_to have_link("Invite a team member")
    end
  end

  context "when the user is a team admin" do
    let(:user) { create(:user, :activated, :team_admin, teams: [team], has_viewed_introduction: true) }
    let(:message_delivery_instance) { instance_double(ActionMailer::MessageDelivery, deliver_now: true) }

    before do
      allow(NotifyMailer).to receive(:invitation_email).with(another_inactive_user, user).and_return(message_delivery_instance)
    end

    scenario "displays the invite a team member link and only displays the resend invite link for inactive users" do
      expect(page).to have_link("Invite a team member")
      expect(page).to have_resend_invite_link_for(another_inactive_user)
      expect(page).not_to have_resend_invite_link_for(another_active_user)
    end

    scenario "resending an invitation sends an email to the user and shows a confirmation message" do
      click_link "Resend invitation to #{another_inactive_user.email}"
      expect(message_delivery_instance).to have_received(:deliver_now)
      expect_confirmation_banner "Invite sent to #{another_inactive_user.email}"
    end
  end

  def expect_to_be_on_team_page
    expect(page).to have_css("h1", text: "test organisation")
  end

  def have_user(user)
    have_css(".teams--user .teams--user-email:contains(\"#{user.email}\")")
  end

  def have_resend_invite_link_for(user)
    have_link("Resend invitation", href: resend_invitation_team_path(team, email_address: user.email))
  end
end
