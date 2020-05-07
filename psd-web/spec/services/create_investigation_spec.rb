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

    expect(service.investigation.assignable).to eq(user)
    expect(service.investigation.case_owner.team).to eq(user.team)
    expect(service.investigation.collaborators.flat_map(&:team)).to include(user.team)
    expect(service.investigation.co_collaborators).to be_empty
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

      expect(investigation.reload.assignable.team).to eq(user.team)
      expect(investigation.case_owner.team).to eq(new_collaborating_case_owner_team)
      expect(investigation.collaborators.flat_map(&:team)).to include(user.team, new_collaborating_case_owner_team)
      expect(investigation.co_collaborators.flat_map(&:team)).to include(user.team)
      expect(investigation.co_collaborators.flat_map(&:team)).not_to include(new_collaborating_case_owner_team)
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

      expect(investigation.reload.assignable.team).to eq(user.team)
      expect(investigation.case_owner.team).to eq(user.team)
      expect(investigation.collaborators.flat_map(&:team)).to include(user.team, new_collaborating_case_owner_team)
      expect(investigation.co_collaborators.flat_map(&:team)).to include(new_collaborating_case_owner_team)
      expect(investigation.co_collaborators.flat_map(&:team)).not_to include(user.team)
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

    expect(investigation.reload.assignable.team).to eq(user.team)
    expect(investigation.case_owner.team).to eq(user.team)
    expect(investigation.collaborators.flat_map(&:team)).to include(user.team, new_collaborating_team)
    expect(investigation.co_collaborators.flat_map(&:team)).to include(new_collaborating_team)
    expect(investigation.co_collaborators.flat_map(&:team)).not_to include(user.team)
  end
end
