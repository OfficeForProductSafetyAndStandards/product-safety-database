RSpec.feature "Your team page", :with_stubbed_mailer, type: :feature do
  let(:team) { create(:team) }
  let(:user) { create(:user, :activated, team:, has_viewed_introduction: true) }

  let!(:another_active_user) { create(:user, :activated, email: "active.sameteam@example.com", organisation: user.organisation, team:, has_viewed_introduction: true) }
  let!(:another_inactive_user) { create(:user, email: "inactive.sameteam@example.com", invited_at: 1.year.ago, organisation: user.organisation, team:) }
  let!(:user_without_details) { create(:user, name: nil, email: "mr.no.details.sameteam@example.com", invited_at: 1.year.ago, organisation: user.organisation, team:) }
  let!(:another_user_another_team) { create(:user, :activated, email: "active.otherteam@example.com", organisation: user.organisation, team: create(:team)) }

  context "when signed in as a member of another team" do
    scenario "it displays a forbidden error" do
      sign_in(another_user_another_team)
      visit "/teams/#{team.id}"
      expect_to_be_on_access_denied_page
    end
  end

  context "when signed in as a member of the team" do
    before do
      sign_in(user)
      visit "/teams/#{team.id}"
      expect_to_be_on_team_page(team)
    end

    context "when the user is not a team admin" do
      scenario "displays the current user but not users belonging to other teams and does not display the resend invite link for any users or the invite a team member link" do
        expect(page).to have_user(user)
        expect(page).to have_user(another_active_user)
        expect(page).to have_user(another_inactive_user)
        expect(page).not_to have_user(another_user_another_team)
        expect(page).not_to have_resend_button_for(another_inactive_user)
        expect(page).not_to have_link("Invite a team member")
        expect(page).not_to have_css("tfoot", text: "Name Email")
      end

      context "when team has 12 or more users" do
        before do
          create_list(:user, 12, organisation: user.organisation, team:)
          visit "/teams/#{team.id}"
          expect_to_be_on_team_page(team)
        end

        it "shows table footers" do
          expect(page).to have_css("tfoot", text: "Name Email")
        end
      end
    end

    context "when the user is a team admin" do
      before do
        user.roles.create!(name: "team_admin")
        visit "/teams/#{team.id}"
      end

      scenario "displays the invite a team member link, awaiting confirmation text and the resend invite link for inactive users that have not yet filled out their details" do
        expect(page).to have_link("Invite another team member")
        expect(page).to have_resend_button_for(user_without_details)
        expect(page).to have_content("Awaiting confirmation for #{user_without_details.email}")
        expect(page).not_to have_resend_button_for(another_active_user)
        expect(page).not_to have_content("Awaiting confirmation for #{another_active_user.email}")
      end

      scenario "resending an invitation sends an email to the user and shows a confirmation message" do
        click_button "Resend invitation to #{user_without_details.email}"
        expect_confirmation_banner "Invite sent to #{user_without_details.email}"

        email = delivered_emails.last

        expect(email.action_name).to eq("invitation_email")
        expect(email.recipient).to eq(user_without_details.email)
        expect(email.personalization[:invitation_url]).to eq("http://www.example.com/users/#{user_without_details.id}/complete-registration?invitation=#{user_without_details.invitation_token}")
        expect(email.personalization[:inviting_team_member_name]).to eq(user.name)
      end
    end
  end

  def have_user(user)
    have_link(user.email)
  end

  def have_resend_button_for(user)
    have_button("Resend invitation to #{user.email}")
  end
end
