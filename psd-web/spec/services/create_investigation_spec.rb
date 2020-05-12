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
