RSpec.describe AuditActivity::Investigation::TeamAdded, :with_stubbed_mailer do
  let(:investigation) { create(:allegation, creator: user, edit_access_teams: [team]) }
  let(:user) { create(:user) }
  let(:team) { create(:team) }

  let(:collaboration) { investigation.edit_access_collaborations.last }
  let(:message) { "This is a message" }

  describe ".build_metadata" do
    let(:result) { described_class.build_metadata(collaboration, message) }

    it "returns a Hash of the arguments" do
      expect(result).to eq({
        team: { id: team.id, name: team.display_name },
        permission: "edit",
        message:
      })
    end
  end
end
