require "rails_helper"

RSpec.describe AuditActivity::CorrectiveAction::Add, :with_stubbed_elasticsearch, :with_stubbed_mailer do
  include_context "with read only team and user"
  include_context "with add corrective action setup"

  subject(:audit_activity) { investigation.activities.find_by(type: described_class.to_s) }
  let(:changes) { corrective_action_form.changes }
  let(:params) do
    corrective_action_form
      .serializable_hash
      .merge(
        investigation: investigation,
        user: user,
        changes: changes
      )
  end

  let!(:corrective_action) { AddCorrectiveActionToCase.call!(params).corrective_action }

  describe ".build_metadata" do
    it "saves the passed changes and corrective action id" do
      expect(described_class.build_metadata(corrective_action, changes))
        .to eq(corrective_action_id: corrective_action.id, updates: changes)
    end
  end

  describe "#title" do
    let(:expected_title) { "#{CorrectiveAction::TRUNCATED_ACTION_MAP[action_key.to_sym]}: #{product.name}" }

    context "when the action is not other" do
      it "shows the action and product name" do
        expect(audit_activity.title).to eq(expected_title)
      end
    end

    context "when the action is set to other" do
      let(:action_key) { "other" }
      let(:other_action) { Faker::Hipster.sentence }

      it "shows the action and product name" do
        expect(audit_activity.title).to eq(other_action)
      end
    end
  end
end
