RSpec.describe UserCollaboratorInterface, :with_stubbed_mailer do
  subject(:user) { create(:user) }

  describe "#team" do
    it { is_expected.to respond_to(:team) }
    it { expect(user.team).to be user.team }
  end

  describe "#user" do
    it { is_expected.to respond_to(:user) }
    it { expect(user.user).to be user }
  end

  describe "own!" do
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

    context "with a user in the same team" do
      let(:other_user_team) { user.team }

      it { expect(user).to be_in_same_team_as(other_user) }
    end

    context "with a user in another team" do
      let(:other_user_team) { create(:team) }

      it { expect(user).not_to be_in_same_team_as(other_user) }
    end
  end
end
