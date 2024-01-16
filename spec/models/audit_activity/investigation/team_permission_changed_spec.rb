RSpec.describe AuditActivity::Investigation::TeamPermissionChanged, :with_stubbed_mailer do
  let(:team) { create(:team) }
  let(:message) { "This is a message" }
  let(:old_permission) { "readonly" }
  let(:new_permission) { "edit" }

  describe ".build_metadata" do
    let(:result) { described_class.build_metadata(team, old_permission, new_permission, message) }

    it "returns a Hash of the arguments" do
      expect(result).to eq({
        team: { id: team.id, name: team.display_name },
        permission: { old: old_permission, new: new_permission },
        message:
      })
    end
  end
end
