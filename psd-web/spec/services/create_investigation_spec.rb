require "rails_helper"

RSpec.describe CreateInvestigation, :with_stubbed_elasticsearch, :with_stubbed_mailer do
  subject(:service) do
    described_class.call(investigation: investigation, current_user: user, assign_to: user)
  end

  let(:investigation) { build :allegation }
  let(:team)          { create :team }
  let(:user)          { create :user, teams: [team] }

  it "creates the investigation", :aggregate_failures do
    expect(service).to be_a_success

    investigation = service.investigation.reload

    expect(investigation.case_creators.where(collaborating: user.team)).to exist
    expect(investigation.case_creators.where(collaborating: user)).to exist
    expect(investigation.case_creator_team.collaborating).to eq(user.team)
    expect(investigation.case_creator_user.collaborating).to eq(user)

    expect(investigation.case_owners.where(collaborating: user.team)).to exist
    expect(investigation.case_owners.where(collaborating: user)).to exist
    expect(investigation.case_owner_team.collaborating).to eq(user.team)
    expect(investigation.case_owner_user.collaborating).to eq(user)

    expect(investigation.collaborators.where(collaborating: team)).not_to exist
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
