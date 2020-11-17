require "rails_helper"

RSpec.feature "Filtering cases", :with_elasticsearch, :with_stubbed_mailer, type: :feature do
  let(:opss_user) { create(:user, :activated, :opss_user, :has_viewed_introduction) }
  let!(:ts_user) { create(:user, :activated, :has_viewed_introduction) }

  before { sign_in opss_user }

  context "when creating a case" do
    let!(:investigation) { create(:allegation, creator: opss_user) }

    context "when assigning to another team" do
      before do
        visit "/cases/#{investigation.pretty_id}/assign/new"
        choose "Other team"
        select ts_user.team.name, from: "Select other team name"
        click_on "Continue"
        click_on "Confirm change"
        click_link "Cases"
      end

      context "when filtering got my cases and my team's cases" do
        before do
          within_fieldset "Case owner" do
            check "Me"
            check "My team"
          end

          click_on "Apply filters"
        end

        it "does not show the newly created case assigned to another team" do
          ap opss_user.team.name
          ap ts_user.team.name
          byebug
          expect(page).not_to have_listed_case(investigation)
        end
      end
    end
  end
end
