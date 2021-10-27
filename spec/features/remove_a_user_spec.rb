require "rails_helper"

RSpec.feature "Removing a user", :with_stubbed_mailer, :with_stubbed_elasticsearch, :with_errors_rendered, type: :feature do
  let(:team) { create(:team) }
  let(:email) { Faker::Internet.safe_email }

  context "when the user is a team admin" do
    let(:user) { create(:user, :activated, :team_admin, team: team, has_viewed_introduction: true, name: "AAAAA") }
    let!(:other_user) { create(:user, :activated, team: team, has_viewed_introduction: true, name: "BBBBB") }

    before do
      sign_in(user)
    end

    context "when user to be removed is activated and not an admin" do
      context "when admin clicks yes to remove user" do
        scenario "user is deleted" do
          visit "/teams/#{team.id}"
          click_link "Remove"

          expect(page.current_path).to eq "/remove_user"

          p user.name
          p other_user.name

          expect(page).to have_content "Do you want to remove #{other_user.name} from your team"

          choose("Yes")

          click_button("Save and continue")

          expect(page.current_path).to eq "/teams/#{team.id}"
          expect(page).to have_content "The team member was removed"
          expect(page).not_to have_content other_user.name
        end
      end

      context "when admin clicks no to remove user" do
        scenario "user is not deleted" do
          visit "/teams/#{team.id}"
          click_link "Remove"

          expect(page.current_path).to eq "/remove_user"

          p user.name
          p other_user.name

          expect(page).to have_content "Do you want to remove #{other_user.name} from your team"

          choose("No")

          click_button("Save and continue")

          expect(page.current_path).to eq "/teams/#{team.id}"
          expect(page).to have_content other_user.name
        end
      end
    end
  end
end
