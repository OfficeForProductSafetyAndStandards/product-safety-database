require "rails_helper"

RSpec.describe AuditActivity::CorrectiveAction::Add, :with_stubbed_elasticsearch, :with_stubbed_mailer do
  let(:corrective_action) { create(:corrective_action) }
  let(:changes) { {"foo" => "bar"} }

  describe ".build_metadata" do
    it "saves the passed changes and corrective action id" do
      expect(described_class.build_metadata(corrective_action, changes))
        .to eq(corrective_action_id: corrective_action.id, updates: changes)
    end
  end
end
