RSpec.describe AuditActivity::Investigation::TeamDeleted, :with_stubbed_mailer do
  let(:team) { create(:team) }
  let(:message) { "This is a message" }

  describe ".build_metadata" do
    let(:result) { described_class.build_metadata(team, message) }

    it "returns a Hash of the arguments" do
      expect(result).to eq({
        team: {
          id: team.id,
          name: team.display_name
        },
        message:
      })
    end
  end
end
