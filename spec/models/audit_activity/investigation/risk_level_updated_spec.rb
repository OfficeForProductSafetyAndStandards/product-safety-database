require "rails_helper"

RSpec.describe AuditActivity::Investigation::RiskLevelUpdated, :with_stubbed_mailer, :with_stubbed_opensearch do
  subject(:audit_activity) { described_class.create(investigation:, metadata:) }

  let(:metadata) { described_class.build_metadata(investigation, update_verb) }
  let(:update_verb) { "changed" }
  let(:previous_risk) { nil }
  let(:new_risk) { nil }
  let(:investigation) { create(:enquiry, risk_level: previous_risk) }

  before { investigation.update!(risk_level: new_risk) }

  describe ".build_metadata" do
    let(:previous_risk) { "low" }
    let(:new_risk) { "other" }

    let(:update_verb) { "changed" }

    it "generates a hash with metadata for the activity" do
      expect(metadata).to eq(
        update_verb:,
        updates: { "risk_level" => [previous_risk, new_risk] }
      )
    end
  end

  describe "#title" do
    let(:user) { build_stubbed(:user) }

    context "when the update_verb is 'set'" do
      let(:update_verb) { "set" }
      let(:previous_risk) { nil }
      let(:new_risk) { "medium" }

      it "generates title based on the update_verb and risk level" do
        expect(audit_activity.title(user)).to eq "Notification risk level set to medium risk"
      end
    end

    context "when the update_verb is 'changed'" do
      let(:update_verb) { "changed" }
      let(:previous_risk) { "low" }
      let(:new_risk) { "medium" }

      it "generates title based on the update_verb and risk level" do
        expect(audit_activity.title(user)).to eq "Notification risk level changed to medium risk"
      end
    end

    context "when the update_verb is 'removed'" do
      let(:update_verb) { "removed" }
      let(:previous_risk) { "low" }
      let(:new_risk) { nil }

      it "generates title based on the update_verb" do
        expect(audit_activity.title(user)).to eq "Notification risk level removed"
      end
    end
  end
end
