require "rails_helper"

RSpec.describe CreateInvestigation, :with_stubbed_elasticsearch, :with_stubbed_mailer do
  subject(:service) do
    described_class.call(investigation_params: investigation_params, user: user)
  end

  let(:investigation_params) { attributes_for :allegation }
  let(:team) { create :team }
  let(:user) { create :user, teams: [team] }

  it "creates the investigation", :aggregate_failures do
    expect(service).to be_a_success

    expect(service.investigation.reload.owner).to eq(user.team)
    expect(service.investigation.owners.where(team: team)).to exist
    expect(service.investigation.collaborators.where(team: team)).to exist
    expect(service.investigation.co_collaborators.where(team: team)).to be_empty
  end
end

RSpec.describe AssignInvestigation, :with_stubbed_elasticsearch, :with_stubbed_mailer do
  subject(:service) do
    described_class.call(investigation: investigation, current_user: user, new_collaborating_case_owner: new_collaborating_case_owner_team)
  end

  let(:investigation_params) { attributes_for :allegation }
  let!(:investigation) { CreateInvestigation.call(investigation_params: investigation_params, user: user).investigation }

  let(:team) { create :team }
  let(:user) { create :user, teams: [team] }

  let(:new_collaborating_case_owner_team) { create :team }

  context "when the new owner is not already a collaborator is in the same team" do
    it "creates the investigation", :aggregate_failures do
      expect(service).to be_a_success

      expect(investigation.reload.case_creator.team).to eq(user.team)
      expect(investigation.reload.case_owner.team).to eq(new_collaborating_case_owner_team)
      expect(service.investigation.owners.where(team: [new_collaborating_case_owner_team, user.team])).to exist
      expect(service.investigation.collaborators.where(team: [new_collaborating_case_owner_team, user.team])).to exist
      expect(service.investigation.collaborators.where(team: new_collaborating_case_owner_team)).to exist
      expect(investigation.co_collaborators.where(team: [user.team, new_collaborating_case_owner_team])).not_to exist
    end
  end

  context "when the new ower is already a collaborator" do
    let(:new_collaborating_case_owner_team_user) { create :user, teams: [new_collaborating_case_owner_team] }

    before { service }

    it "re assigns the investigation to the already existing collaborator", :aggregate_failures do
      expect {
        described_class.call(
          investigation: investigation,
          current_user: new_collaborating_case_owner_team_user,
          new_collaborating_case_owner: user.team
        )
      }.not_to(change { investigation.collaborators.count })

      expect(investigation.reload.owner.team).to eq(user.team)

      expect(investigation.case_creator.team).to eq(user.team)
      expect(investigation.case_owner.team).to eq(user.team)
      expect(investigation.collaborators.where(team: [user.team, new_collaborating_case_owner_team]).count).to eq(2)
      expect(investigation.co_collaborators.where(team: new_collaborating_case_owner_team)).to exist
      expect(investigation.co_collaborators.where(team: user.team)).not_to exist
    end
  end
end

RSpec.describe AddTeamToAnInvestigation, :with_stubbed_elasticsearch, :with_stubbed_mailer do
  subject(:service) do
    described_class.call(
      team_id: new_collaborating_team.id,
      include_message: "true",
      message: "Thanks for collaborating.",
      investigation: investigation,
      current_user: user
    )
  end

  let(:investigation_params) { attributes_for :allegation }
  let!(:investigation) { CreateInvestigation.call(investigation_params: investigation_params, user: user).investigation }

  let(:team) { create :team }
  let(:user) { create :user, teams: [team] }

  let(:new_collaborating_team) { create(:team) }

  it "correctly assigns add a collaborator", :aggregate_failures do
    expect(service).to be_a_success

    expect(investigation.reload.owner).to eq(user.team)
    expect(investigation.creator.team).to eq(user.team)

    expect(investigation.collaborators.where(team: [user.team, new_collaborating_team]).count).to eq(2)
    expect(investigation.co_collaborators.where(team: new_collaborating_team)).to exist
    expect(investigation.owners.where(team: user.team)).to exist
  end
end
