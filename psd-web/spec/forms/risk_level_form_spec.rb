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

      it "discards the value for 'risk_level_other' attribute" do
        expect(form.risk_level_other).to be_nil
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

  describe "#valid?" do
    shared_examples_for "valid form" do
      it "is is valid" do
        expect(form).to be_valid
      end

      it "does not contain error messages" do
        form.validate
        expect(form.errors.full_messages).to be_empty
      end
    end

    shared_examples_for "invalid form" do |*errors|
      it "is not valid" do
        expect(form).to be_invalid
      end

      it "populates an error message" do
        form.validate
        errors.each do |property, message|
          expect(form.errors.full_messages_for(property)).to eq([message])
        end
      end

      it "keeps the original risk_level in the form" do
        form.validate
        expect(form.risk_level).to eq risk_level
      end

      it "keeps the original risk_level_other in the form" do
        form.validate
        expect(form.risk_level_other).to eq risk_level_other
      end
    end

    context "when neither the risk_level or the risk_level_other are set" do
      let(:risk_level) { nil }
      let(:risk_level_other) { nil }

      include_examples "valid form"
    end

    context "when risk level is set to any of the standard levels" do
      let(:risk_level) { "Low risk" }

      context "with risk_level_other" do
        let(:risk_level_other) { "custom risk" }

        include_examples "valid form"
      end

      context "without risk_level_other" do
        let(:risk_level_other) { nil }

        include_examples "valid form"
      end
    end

    context "when risk level is set to 'other'" do
      let(:risk_level) { "other" }

      context "with risk_level_other" do
        let(:risk_level_other) { "custom risk" }

        include_examples "valid form"
      end

      context "without risk_level_other" do
        let(:risk_level_other) { nil }

        include_examples "invalid form", [:risk_level_other, "Set a risk level"]
      end
    end

    context "when risk level is set to a non allowed value" do
      let(:risk_level) { "random risk" }

      context "with risk_level_other" do
        let(:risk_level_other) { "custom risk" }

        include_examples "invalid form", [:risk_level, "Invalid option"]
      end

      context "without risk_level_other" do
        let(:risk_level_other) { nil }

        include_examples "invalid form", [:risk_level, "Invalid option"]
      end
    end
  end
end
