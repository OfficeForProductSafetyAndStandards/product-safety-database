require "rails_helper"

RSpec.describe RiskLevelForm do
  subject(:form) { described_class.new(risk_level: risk_level, risk_level_other: risk_level_other) }

  describe "#initialize" do
    context "when risk level is set as 'other'" do
      let(:risk_level) { "other" }
      let(:risk_level_other) { "very very risky" }

      it "sets 'risk_level' attribute from 'risk_level_other'" do
        expect(form.risk_level).to eq risk_level_other
      end

      it "keeps the value for 'risk_level_other' attribute" do
        expect(form.risk_level_other).to eq risk_level_other
      end
    end

    context "when risk level belongs to the list of standard ones" do
      let(:risk_level) { Investigation::STANDARD_RISK_LEVELS.first }
      let(:risk_level_other) { "whatever level" }

      it "keeps the value for risk level attribute" do
        expect(form.risk_level).to eq risk_level
      end

      it "deletes the value for 'risk_level_other' attribute" do
        expect(form.risk_level_other).to be_nil
      end
    end

    context "when risk level does not belong to the list of standard ones" do
      let(:risk_level) { "very very risky" }
      let(:risk_level_other) { "whatever level" }

      it "sets the risk level attribute value to 'other'" do
        expect(form.risk_level).to eq "other"
      end

      it "sets the non standard risk level in 'risk_level_other' attribute" do
        expect(form.risk_level_other).to eq risk_level
      end
    end

    context "when the risk level is not set" do
      let(:risk_level) { nil }
      let(:risk_level_other) { "very very risky" }

      it "keeps the unset value for risk level attribute " do
        expect(form.risk_level).to be_nil
      end

      it "deletes the value for 'risk_level_other' attribute" do
        expect(form.risk_level_other).to be_nil
      end
    end
  end
end
