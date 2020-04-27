require "rails_helper"

RSpec.feature "Your team page", :with_stubbed_mailer, :with_stubbed_elasticsearch, type: :feature do
  let(:team) { create(:team) }
  let(:user) { create(:user, :activated, teams: [team], has_viewed_introduction: true) }

  let!(:another_active_user) { create(:user, :activated, email: "active.sameteam@example.com", organisation: user.organisation, teams: [team], has_viewed_introduction: true) }
  let!(:another_inactive_user) { create(:user, email: "inactive.sameteam@example.com", organisation: user.organisation, teams: [team]) }
  let!(:another_user_another_team) { create(:user, :activated, email: "active.otherteam@example.com", organisation: user.organisation, teams: [create(:team)]) }

  before do
    sign_in(user)
    visit team_path(team)
  end

  scenario "shows the current user" do
    expect(page).to have_css(".teams--user .teams--user-email:contains(\"#{user.email}\")")
    expect(page).to have_css(".teams--user .teams--user-email:contains(\"#{another_active_user.email}\")")
    expect(page).to have_css(".teams--user .teams--user-email:contains(\"#{another_inactive_user.email}\")")
    expect(page).not_to have_css(".teams--user .teams--user-email:contains(\"#{another_user_another_team.email}\")")
  end

  def resend_link_selector(email)
    "a[href=\"#{resend_invitation_team_path(team)}?email_address=#{CGI.escape(email)}\"]"
  end

  context "when the user is a team admin" do
    let(:user) { create(:user, :activated, :team_admin, teams: [team], has_viewed_introduction: true) }

    scenario "only displays the resend invite link for inactive users" do
      expect(page).to have_css(resend_link_selector(another_inactive_user.email))
      expect(page).not_to have_css(resend_link_selector(another_active_user.email))
    end

    scenario "inviting an existing user shows an error message" do
      click_link "Invite a team member"
      expect(page).to have_css("h1", text: "Invite a team member")
      fill_in "new_user_email_address", with: user.email
      click_button "Send invitation email"
      expect(page).to have_css(".govuk-error-summary__list", text: "You cannot invite this person to join your team because they are already a member of another team from a different organisation.")
    end

    scenario "inviting a deleted user shows an error message" do
      deleted_user = create(:user, deleted: true)
      click_link "Invite a team member"
      expect(page).to have_css("h1", text: "Invite a team member")
      fill_in "new_user_email_address", with: deleted_user.email
      click_button "Send invitation email"
      expect(page).to have_css(".govuk-error-summary__list", text: "Email address belongs to a user that has been deleted. Email OPSS if you would like their account restored.")
    end
  end

  context "when the user is not a team admin" do
    let(:user) { create(:user, :activated, :psd_user, teams: [team], has_viewed_introduction: true) }

    scenario "does not display the resend invite link for any users" do
      expect(page).to have_css("h1", text: "test organisation")
      expect(page).not_to have_link(resend_link_selector(another_inactive_user.email))
    end

    scenario "does not display the invite a team member link" do
      expect(page).to have_css("h1", text: "test organisation")
      expect(page).not_to have_button("Invite a team member")
    end
  end
end
