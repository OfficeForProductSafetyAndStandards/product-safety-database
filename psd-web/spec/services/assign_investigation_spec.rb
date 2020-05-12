require "rails_helper"

RSpec.describe AssignInvestigation, :with_stubbed_elasticsearch, :with_stubbed_mailer do
  subject(:service) do
    described_class.call(
      investigation: investigation,
      current_user: user,
      new_collaborating_case_owner: new_collaborating_case_owner_team
    )
  end

  let!(:investigation) do
    CreateInvestigation
      .call(investigation: build(:allegation), current_user: user)
      .investigation
  end

  let(:team) { create :team, team_recipient_email: "creator.team@example.com" }
  let(:user) { create :user, teams: [team], email: "creator.user@example.com" }

  let(:new_collaborating_case_owner_team) { create :team, team_recipient_email: "newly.assigned.team@example.com" }

  context "when the new owner is not already a collaborator is in the same team" do
    it "creates the investigation", :aggregate_failures do
      expect(service).to be_a_success

      investigation.reload

      expect(investigation.case_creators.where(collaborating: user.team)).to exist
      expect(investigation.case_creators.where(collaborating: user)).to exist
      expect(investigation.case_creator_team.collaborating).to eq(user.team)
      expect(investigation.case_creator_user.collaborating).to eq(user)

      expect(investigation.case_owners.where(collaborating: new_collaborating_case_owner_team)).to exist
      expect(investigation.case_owner_team.collaborating).to eq(new_collaborating_case_owner_team)
      expect(investigation.case_owner_user).to be nil

      expect(investigation.collaborators.where(collaborating: user.team)).to exist
    end
  end

  context "when the new ower is already a collaborator" do
    let(:new_collaborating_case_owner_team_user) { create :user, teams: [new_collaborating_case_owner_team] }

    before do
      described_class.call(
        investigation: investigation,
        current_user: new_collaborating_case_owner_team_user,
        new_collaborating_case_owner: user.team
      )
    end

    it "re assigns the investigation to the already existing collaborator", :aggregate_failures do
      service

      expect(investigation.case_creators.where(collaborating: user.team)).to exist
      expect(investigation.case_creators.where(collaborating: user)).to exist
      expect(investigation.case_creator_team.collaborating).to eq(user.team)
      expect(investigation.case_creator_user.collaborating).to eq(user)
      expect(investigation.collaborators.where(collaborating: new_collaborating_case_owner_team)).to exist
      expect(investigation.case_owners.where(collaborating: user.team)).to exist
      expect(investigation.case_owner_user.collaborating).to eq(user)
      expect(investigation.collaborators.count).to eq(1)
    end
  end
end
