require "rails_helper"

RSpec.describe AuditActivity::Investigation::RiskLevelUpdated, :with_stubbed_mailer, :with_stubbed_elasticsearch do
  subject(:audit_activity) { described_class.from(investigation, action: action, source: source) }

  let(:user) { create(:user) }
  let(:source) { UserSource.new(user: user) }
  let(:previous_risk_level) { nil }
  let(:new_risk_level) { nil }
  let(:investigation) { create(:enquiry, risk_level: previous_risk_level) }

  before do
    investigation.risk_level = new_risk_level
    investigation.save
  end

  describe ".from" do
    let(:previous_risk_level) { "Medium risk" }
    let(:new_risk_level) { "High risk" }

    let(:action) { "changed" }

    it "creates an audit activity", :aggregate_failures do
      expect(audit_activity).to have_attributes(
        source: source,
        investigation: investigation,
        metadata: { "action" => action, "previous_risk_level" => previous_risk_level, "new_risk_level" => new_risk_level },
        body: nil
      )
    end
  end

  describe "#title" do
    context "when the action is 'set'" do
      let(:previous_risk_level) { nil }
      let(:new_risk_level) { "Medium risk" }
      let(:action) { "set" }

      it "generates title based on the action and risk level" do
        expect(audit_activity.title(user)).to eq "Case risk level set to medium risk"
      end
    end

    context "when the action is 'changed'" do
      let(:previous_risk_level) { "Low risk" }
      let(:new_risk_level) { "Medium risk" }
      let(:action) { "changed" }

      it "generates title based on the action and risk level" do
        expect(audit_activity.title(user)).to eq "Case risk changed to medium risk"
      end
    end

    context "when the action is 'removed'" do
      let(:previous_risk_level) { "Low risk" }
      let(:new_risk_level) { nil }
      let(:action) { "removed" }

      it "generates title based on the action" do
        expect(audit_activity.title(user)).to eq "Case risk level removed"
      end
    end
  end
end
