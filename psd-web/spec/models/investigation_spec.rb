require "rails_helper"

RSpec.describe Investigation, :with_stubbed_elasticsearch, :with_stubbed_mailer, :with_stubbed_notify do
  describe "#teams_with_access" do
    context "when there is no case owner" do
      let(:investigation) { create(:investigation, owner: nil) }

      it "is an empty list" do
        expect(investigation.teams_with_access).to be_empty
      end
    end

    context "when there is just a team that is the case owner" do
      let(:team) { create(:team) }
      let(:investigation) { create(:investigation, owner: team) }

      it "is a list of just the team" do
        expect(investigation.teams_with_access).to eql([team])
      end
    end

    context "when there is a team as the case owner and a collaborator team added" do
      let(:team) { create(:team) }
      let(:collaborator_team) { create(:team) }
      let(:investigation) do
        create(
          :investigation,
          owner: team,
          collaborators: [
            create(:collaborator, team: collaborator_team)
          ]
        )
      end

      it "is a list of the team and the collaborator team" do
        expect(investigation.teams_with_access).to match_array([team, collaborator_team])
      end
    end
  end

  describe "#owner_team" do
    context "when there is no case owner" do
      let(:investigation) { create(:investigation, owner: nil) }

      it "is nil" do
        expect(investigation.owner_team).to be_nil
      end
    end

    context "when there is a team as the case owner" do
      let(:team) { create(:team) }
      let(:investigation) { create(:investigation, owner: team) }

      it "is is the team" do
        expect(investigation.owner_team).to eql(team)
      end
    end

    context "when there is a user who belongs to a team that is the case owner" do
      let(:team) { create(:team) }
      let(:user) { create(:user, team: team) }
      let(:investigation) { create(:investigation, owner: user) }

      it "is is the team the user belongs to" do
        expect(investigation.owner_team).to eql(team)
      end
    end
  end
end
