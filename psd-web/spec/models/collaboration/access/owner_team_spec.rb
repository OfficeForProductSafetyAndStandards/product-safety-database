require "rails_helper"

RSpec.describe Collaboration::Access::OwnerTeam, :with_stubbed_elasticsearch, :with_stubbed_mailer do
  subject(:owner_team_collaboration) { investigation.owner_team_collaboration }

  let(:investigation) { create(:allegation) }
  let(:team) { investigation.team }
  let(:user) { investigation.user }

  describe "#swap_to_edit_access!" do
    it "swaps the current collaboration to be an editor", :aggregate_failures do
      expect { owner_team_collaboration.swap_to_edit_access! }
        .to change { investigation.collaboration_accesses.find_by(collaborator: team) }
              .from(instance_of(described_class)).to(instance_of(Collaboration::Access::Edit))
        .and change { investigation.collaboration_accesses.find_by(collaborator: user) }.from(instance_of(Collaboration::Access::OwnerUser)).to(nil)
    end
  end
end
