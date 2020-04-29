require "rails_helper"

RSpec.feature "Inviting a user", :with_stubbed_mailer, :with_stubbed_elasticsearch, type: :feature do
  let(:team) { create(:team) }
  let(:user) { create(:user, :activated, :team_admin, teams: [team], has_viewed_introduction: true) }

  before do
    sign_in(user)
    visit invite_to_team_url(team)
    expect_to_be_on_invite_a_team_member_page
  end

  context "when there is already a user with that email" do
    scenario "shows an error message" do
      fill_in "new_user_email_address", with: user.email
      click_button "Send invitation email"
      expect(page).to have_css(".govuk-error-summary__list", text: "You cannot invite this person to join your team because they are already a member of another team from a different organisation.")
    end
  end

  def expect_to_be_on_invite_a_team_member_page
    expect(page).to have_css("h1", text: "Invite a team member")
  end
end
