require "rails_helper"

RSpec.describe "Viewing a restricted case", :with_stubbed_mailer, :with_stubbed_notify, type: :request do
  let(:users_organisation) { create(:organisation, name: "Org A") }
  let(:users_team) { create(:team, organisation: users_organisation, name: "Team A") }
  let(:user) { create(:user, :activated, organisation: users_organisation, team: users_team) }

  let(:other_team_from_the_same_organisation) { create(:team, organisation: users_organisation, name: "Team B") }

  let(:other_organisation) { create(:organisation) }
  let(:other_team) { create(:team, organisation: other_organisation) }
  let(:other_user) { create(:user, :activated, organisation: other_organisation, team: other_team) }
  let(:other_user_same_org) { create(:user, :activated, organisation: users_organisation, team: other_team_from_the_same_organisation) }

  before do
    sign_in user
    get investigation_path(investigation.pretty_id)
  end

  context "when the user’s team is the case owner" do
    let(:investigation) { create(:allegation, is_private: true, creator: user) }

    it "renders the page" do
      expect(response).to have_http_status(:ok)
    end
  end

  context "when another team from the same organisation is the case owner" do
    let(:investigation) { create(:allegation, is_private: true, creator: other_user_same_org) }

    it "displays an forbidden message" do
      expect(response).to have_http_status(:forbidden)
    end
  end

  context "when a team from a different organisation is the case owner" do
    let(:investigation) { create(:allegation, is_private: true, creator: create(:user, team: other_team)) }

    it "displays an forbidden message" do
      expect(response).to have_http_status(:forbidden)
    end
  end

  context "when a user from from a different organisation is the case owner" do
    let(:investigation) { create(:allegation, is_private: true, creator: other_user) }

    it "displays an forbidden message" do
      expect(response).to have_http_status(:forbidden)
    end
  end

  context "when the case is owned by a team from another organisation but the user’s team has been added as a collaborator" do
    let(:investigation) do
      create(
        :allegation,
        is_private: true,
        creator: create(:user, team: other_team),
        edit_access_collaborations: [
          create(:collaboration_edit_access, collaborator: users_team, added_by_user: other_user)
        ]
      )
    end

    it "renders the page" do
      expect(response).to have_http_status(:ok)
    end
  end

  context "when the case is owned by a team from another organisation and the user has the restricted_case_viewer role" do
    let(:investigation) { create(:allegation, is_private: true, creator: other_user) }
    let(:user) { create(:user, :activated, :restricted_case_viewer, organisation: users_organisation, team: users_team,) }

    it "renders the page" do
      expect(response).to have_http_status(:ok)
    end
  end
end
