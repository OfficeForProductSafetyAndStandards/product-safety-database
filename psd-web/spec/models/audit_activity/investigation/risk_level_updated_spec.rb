require "rails_helper"

RSpec.describe AuditActivity::Investigation::RiskLevelUpdated, :with_stubbed_mailer, :with_stubbed_elasticsearch do
  subject(:audit_activity) { described_class.create_for!(investigation, update_verb: update_verb, source: source) }

  let(:user) { create(:user) }
  let(:source) { UserSource.new(user: user) }
  let(:previous_risk) { nil }
  let(:previous_custom) { nil }
  let(:new_risk) { nil }
  let(:new_custom) { nil }
  let(:investigation) { create(:enquiry, risk_level: previous_risk, custom_risk_level: previous_custom) }

  before { investigation.update!(risk_level: new_risk, custom_risk_level: new_custom) }

  describe ".create_for!" do
    let(:previous_risk) { "low" }
    let(:new_risk) { "other" }
    let(:previous_custom) { nil }
    let(:new_custom) { "Custom risk" }

    let(:update_verb) { "changed" }

    it "creates an audit activity reflecting the change action and value updates" do
      expect(audit_activity).to have_attributes(
        source: source,
        investigation: investigation,
        metadata: { "update_verb" => update_verb,
                    "updates" => { "risk_level" => [previous_risk, new_risk],
                                   "custom_risk_level" => [previous_custom, new_custom] } }
      )
    end
  end

  describe "#title" do
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
