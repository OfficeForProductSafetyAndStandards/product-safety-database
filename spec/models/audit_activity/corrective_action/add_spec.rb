require "rails_helper"

RSpec.describe AuditActivity::CorrectiveAction::Add, :with_stubbed_elasticsearch, :with_stubbed_mailer, :with_stubbed_antivirus do
  include_context "with read only team and user"
  include_context "with add corrective action setup"

  subject(:audit_activity) { described_class.new(metadata: metadata, product: product) }

  let(:metadata) { described_class.build_metadata(corrective_action) }
  let!(:corrective_action) { create(:corrective_action, action: action_key, other_action: other_action) }

  describe ".build_metadata" do
    context "with no document attached" do
      it "saves the passed changes and corrective action id" do
        expect(described_class.build_metadata(corrective_action))
          .to eq(corrective_action: corrective_action.attributes, document: nil)
      end
    end

    context "with a document attached" do
      let!(:corrective_action) { create(:corrective_action, :with_document) }

      it "saves the passed changes and corrective action id" do
        expect(described_class.build_metadata(corrective_action))
          .to eq(corrective_action: corrective_action.attributes, document: corrective_action.document.attributes)
      end
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
