require "rails_helper"

RSpec.describe AuditActivity::Investigation::RiskLevelUpdated, :with_stubbed_mailer, :with_stubbed_elasticsearch do
  subject(:audit_activity) { described_class.create(investigation: investigation, metadata: metadata) }

  let(:metadata) { described_class.build_metadata(investigation, update_verb) }
  let(:update_verb) { "changed" }
  let(:previous_risk) { nil }
  let(:previous_custom) { nil }
  let(:new_risk) { nil }
  let(:new_custom) { nil }
  let(:investigation) { create(:enquiry, risk_level: previous_risk, custom_risk_level: previous_custom) }

  before { investigation.update!(risk_level: new_risk, custom_risk_level: new_custom) }

  describe ".build_metadata" do
    let(:previous_risk) { "low" }
    let(:new_risk) { "other" }
    let(:previous_custom) { nil }
    let(:new_custom) { "Custom risk" }

    let(:update_verb) { "changed" }

    it "generates a hash with metadata for the activity" do
      expect(metadata).to eq(
        update_verb: update_verb,
        updates: { "risk_level" => [previous_risk, new_risk],
                   "custom_risk_level" => [previous_custom, new_custom] }
      )
    end
  end

  describe "#title" do
    let(:user) { build_stubbed(:user) }

    context "when the update_verb is 'set'" do
      let(:update_verb) { "set" }

      context "with an update on risk level" do
        let(:previous_risk) { nil }
        let(:new_risk) { "medium" }
        let(:previous_custom) { nil }
        let(:new_custom) { nil }

        it "generates title based on the update_verb and risk level" do
          expect(audit_activity.title(user)).to eq "Case risk level set to medium risk"
        end
      end

      context "with an update on custom risk level" do
        let(:previous_risk) { nil }
        let(:new_risk) { "other" }
        let(:previous_custom) { nil }
        let(:new_custom) { "Custom risk" }

        it "generates title based on the update_verb and custom risk" do
          expect(audit_activity.title(user)).to eq "Case risk level set to custom risk"
        end
      end
    end

    context "when the update_verb is 'changed'" do
      let(:update_verb) { "changed" }

      context "with an update on risk level" do
        let(:previous_risk) { "low" }
        let(:new_risk) { "medium" }
        let(:previous_custom) { nil }
        let(:new_custom) { nil }

        it "generates title based on the update_verb and risk level" do
          expect(audit_activity.title(user)).to eq "Case risk level changed to medium risk"
        end
      end

      context "with an update on custom risk level" do
        let(:previous_risk) { "other" }
        let(:new_risk) { "other" }
        let(:previous_custom) { "mild risk" }
        let(:new_custom) { "Custom risk" }

        it "generates title based on the update_verb and custom risk" do
          expect(audit_activity.title(user)).to eq "Case risk level changed to custom risk"
        end
      end
    end

    context "when the update_verb is 'removed'" do
      let(:previous_risk) { "low" }
      let(:new_risk) { nil }
      let(:update_verb) { "removed" }

      it "generates title based on the update_verb" do
        expect(audit_activity.title(user)).to eq "Case risk level removed"
      end
    end
  end
end
