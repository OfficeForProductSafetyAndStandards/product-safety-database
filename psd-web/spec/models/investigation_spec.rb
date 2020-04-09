require "rails_helper"

RSpec.describe Investigation, :with_stubbed_elasticsearch, :with_stubbed_mailer, :with_stubbed_notify do
  describe "#teams_with_access" do
    context "when there is no-one assigned" do
      let(:investigation) { create(:investigation, assignable: nil) }

  describe "setting reported_reason from separate boolean attributes" do

    context "when there is just a team assigned" do
      let(:team) { create(:team) }
      let(:investigation) { create(:investigation, assignable: team) }

    context "when setting only unsafe to true" do
      before do
        investigation.reported_reason_unsafe = true
        investigation.reported_reason_non_compliant = false
        investigation.reported_reason_safe_and_compliant = false
      end

    context "when there is a team assigned and a collaborator team added" do
      let(:team_assigned) { create(:team) }
      let(:collaborator_team) { create(:team) }
      let(:investigation) {
        create(:investigation,
               assignable: team_assigned,
               collaborators: [
                 create(:collaborator, team: collaborator_team)
               ])
      }

      it "is a list of the team assigned and the collaborator team" do
        expect(investigation.teams_with_access).to match_array([team_assigned, collaborator_team])
      end
    end
  end

  describe "#assignee_team" do
    context "when there is no-one assigned" do
      let(:investigation) { create(:investigation, assignable: nil) }

    context "when setting only non_compliant to true" do
      before do
        investigation.reported_reason_unsafe = false
        investigation.reported_reason_non_compliant = true
        investigation.reported_reason_safe_and_compliant = false
      end
    end

    context "when there is a team assigned" do
      let(:team) { create(:team) }
      let(:investigation) { create(:investigation, assignable: team) }

      it "sets the reported_reason to `non_compliant`" do
        expect(investigation.reported_reason).to eql(:non_compliant)
      end
    end

    context "when setting only safe_and_compliant to true" do
      before do
        investigation.reported_reason_unsafe = false
        investigation.reported_reason_non_compliant = false
        investigation.reported_reason_safe_and_compliant = true
      end

      it "sets the reported_reason to `safe_and_compliant`" do
        expect(investigation.reported_reason).to eql(:safe_and_compliant)
      end
    end

    context "when there is a user who doesn’t belong to a team assigned" do
      let(:user) { create(:user, teams: []) }
      let(:investigation) { create(:investigation, assignable: user) }

      it "sets the reported_reason to `nil`" do
        expect(investigation.reported_reason).to be_nil
      end
    end

  end

end
