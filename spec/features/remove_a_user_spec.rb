require "rails_helper"

RSpec.feature "Removing a user", :with_stubbed_mailer, type: :feature do
  let(:team) { create(:team) }
  let(:email) { Faker::Internet.email }
  let!(:other_user) { create(:user, :activated, team:, has_viewed_introduction: true) }

  context "when the user is a team admin" do
    let(:user) { create(:user, :activated, :team_admin, team:, has_viewed_introduction: true) }

    before do
      sign_in(user)
    end

    context "when user to be removed is activated and not an admin" do
      context "when admin clicks yes to remove user" do
        scenario "user is deleted" do
          visit "/teams/#{team.id}"
          click_link "Remove"

          expect(page).to have_content "Do you want to remove #{other_user.name} from your team"

          choose("Yes")

          click_button("Save and continue")

          expect(page).to have_current_path "/teams/#{team.id}", ignore_query: true
          expect(page).to have_content "The team member was removed"
          expect(page).not_to have_content other_user.name
        end

        context "when admin clicks no to remove user" do
          scenario "user is not deleted" do
            visit "/teams/#{team.id}"
            click_link "Remove"

            expect(page).to have_content "Do you want to remove #{other_user.name} from your team"

            choose("No")

            click_button("Save and continue")

            expect(page).to have_current_path "/teams/#{team.id}", ignore_query: true
            expect(page).to have_content other_user.name
          end
        end

        context "when an admin removes a user then clicks back" do
          scenario "user is deleted once" do
            visit "/teams/#{team.id}"
            click_link "Remove"

            expect(page).to have_content "Do you want to remove #{other_user.name} from your team"

            choose("Yes")

            click_button("Save and continue")

            expect(page).to have_current_path "/teams/#{team.id}", ignore_query: true
            expect(page).to have_content "The team member was removed"
            expect(page).not_to have_content other_user.name

            visit remove_user_path(user_id: other_user.id)

            expect(page).to have_content "Do you want to remove #{other_user.name} from your team"

            choose("Yes")

            click_button("Save and continue")

            expect(page).to have_current_path "/teams/#{team.id}", ignore_query: true
            expect(page).to have_content "The team member has already been removed"
            expect(page).not_to have_content other_user.name
          end
        end

        context "when admin does not select an option" do
          scenario "shows error message" do
            visit "/teams/#{team.id}"
            click_link "Remove"

            expect(page).to have_content "Do you want to remove #{other_user.name} from your team"

            click_button("Save and continue")

            expect(page).to have_content "Select yes if you want to remove the team member from your team"
          end
        end
      end

      context "when user to be removed is not activated and not an admin" do
        before do
          other_user.update!(account_activated: false, name: nil)
        end

        context "when admin clicks yes to remove user" do
          scenario "user is deleted" do
            visit "/teams/#{team.id}"
            click_link "Remove"

            expect(page).to have_content "Do you want to remove the team member from your team"

            choose("Yes")

            click_button("Save and continue")

            expect(page).to have_current_path "/teams/#{team.id}", ignore_query: true
            expect(page).to have_content "The team member was removed"
          end
        end
      end
    end

    context "when the user is not a team admin" do
      let(:user) { create(:user, :activated, team:, has_viewed_introduction: true) }

      scenario "does not allow user to remove other users" do
        visit "/teams/#{team.id}"
        expect(page).not_to have_link "Remove"
      end
    end

    context "when the user to be removed is a team admin" do
      before do
        other_user.roles.create!(name: "team_admin")
      end

      scenario "does not allow user to remove other users" do
        visit "/teams/#{team.id}"
        expect(page).not_to have_link "Remove"
      end
    end
  end
end
