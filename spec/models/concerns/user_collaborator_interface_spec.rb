require "rails_helper"

RSpec.describe UserCollaboratorInterface, :with_stubbed_mailer do
  subject(:user) { create(:user) }

  describe "#team" do
    let(:team) { create(:team) }

    before do
      user.team = team
    end

    it { is_expected.to respond_to(:team) }

    it "returns the correct team" do
      expect(user.team).to eq(team)
    end

    context "when user has no team" do
      before do
        user.team = nil
      end

      it "returns nil" do
        expect(user.team).to be_nil
      end
    end
  end

  describe "#user" do
    it { is_expected.to respond_to(:user) }
    it { expect(user.user).to be user }
  end

  describe "#own!" do
    let(:investigation) { create(:allegation) }
    let(:old_user)      { investigation.owner_user }
    let(:old_team)      { investigation.owner_team }

    it "swaps to the new owner" do
      expect { user.own!(investigation) && investigation.reload }
        .to change(investigation, :owner_user).from(old_user).to(user)
        .and change(investigation, :owner_team).from(old_team).to(user.team)
    end
  end

  describe "#in_same_team_as?" do
    let(:other_user) { create(:user, team: other_user_team) }

    context "when the other user is in the same team" do
      let(:other_user_team) { user.team }

      it "returns true" do
        expect(user).to be_in_same_team_as(other_user)
      end
    end

    context "when the other user is in a different team" do
      let(:other_user_team) { create(:team) }

      it "returns false" do
        expect(user).not_to be_in_same_team_as(other_user)
      end
    end
  end
end
