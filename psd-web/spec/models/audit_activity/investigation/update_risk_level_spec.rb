require "rails_helper"

RSpec.describe AuditActivity::Investigation::UpdateRiskLevel, :with_stubbed_mailer, :with_stubbed_elasticsearch do
  subject(:audit_activity) { described_class.from(investigation, action: action) }

  let(:user) { create(:user).decorate }
  let(:investigation) { create(:enquiry, risk_level: "Medium Risk") }

  before { User.current = user }

  describe ".from" do
    let(:action) { "changed" }

    it "creates an audit activity", :aggregate_failures do
      expect(audit_activity).to have_attributes(
        investigation: investigation,
        metadata: { "action" => action, "risk_level" => "Medium Risk" },
        body: nil
      )
    end
  end

  describe "#title" do
    context "when the action is 'set'" do
      let(:action) { "set" }

      it "generates title based on the action and risk level" do
        expect(audit_activity.title(user)).to eq "Case risk level set to medium risk"
      end
    end

    context "when the action is 'changed'" do
      let(:action) { "changed" }

      it "generates title based on the action and risk level" do
        expect(audit_activity.title(user)).to eq "Case risk changed to medium risk"
      end
    end

    context "when the action is 'removed'" do
      let(:action) { "removed" }

      it "generates title based on the action" do
        expect(audit_activity.title(user)).to eq "Case risk level removed"
      end
    end
  end
end
