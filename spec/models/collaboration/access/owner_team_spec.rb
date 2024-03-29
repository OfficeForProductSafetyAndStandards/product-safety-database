require "rails_helper"

RSpec.describe Collaboration::Access::OwnerTeam, :with_stubbed_mailer do
  subject(:owner_team_collaboration) { notification.owner_team_collaboration }

  let(:notification) { create(:notification) }
  let(:team) { notification.owner_team }
  let(:user) { notification.owner_user }

  describe ".changeable?" do
    it "returns false" do
      expect(described_class).not_to be_changeable
    end
  end

  describe "#swap_to_edit_access!" do
    context "when the previous owner was a user" do
      it "swaps the current collaboration to be an editor", :aggregate_failures do
        expect { owner_team_collaboration.swap_to_edit_access! }
          .to change { notification.collaboration_accesses.find_by(collaborator: team) }
                .from(instance_of(described_class)).to(instance_of(Collaboration::Access::Edit))
                .and change { notification.collaboration_accesses.find_by(collaborator: user) }.from(instance_of(Collaboration::Access::OwnerUser)).to(nil)
      end
    end

    context "when the previous owner was a team" do
      before do
        ChangeNotificationOwner.call!(notification:, owner: team, user:)
        notification.reload
      end

      it "swaps the current collaboration to be an editor", :aggregate_failures do
        expect {
          notification.owner_team_collaboration.swap_to_edit_access!
        }.not_to change(notification, :owner_user_collaboration)
      end
    end
  end
end
