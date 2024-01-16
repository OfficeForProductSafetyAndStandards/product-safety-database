RSpec.describe TeamCollaboratorInterface, :with_stubbed_mailer do
  subject(:team) { user.team }

  let(:user) { create(:user) }

  describe "#team" do
    it { is_expected.to respond_to(:team) }
    it { expect(team.team).to be team }
  end

  describe "#user" do
    it { is_expected.to respond_to(:user) }
    it { expect(team.user).to be_nil }
  end

  describe "own!" do
    let(:investigation) { create(:allegation) }
    let(:old_user)      { investigation.owner_user }
    let(:old_team)      { investigation.owner_team }

    it "swaps to the new owner" do
      expect { team.own!(investigation) && investigation.reload }
        .to change(investigation, :owner_team).from(old_team).to(team)
              .and change(investigation, :owner_user).from(old_user).to(nil)
    end
  end

  describe "#in_same_team_as?" do
    let(:other_user) { create(:user, team: other_user_team) }

    context "with a user in the same team" do
      let(:other_user_team) { team }

      it { expect(team).to be_in_same_team_as(other_user) }
    end

    context "with a user in another team" do
      let(:other_user_team) { create(:team) }

      it { expect(team).not_to be_in_same_team_as(other_user) }
    end
  end
end
