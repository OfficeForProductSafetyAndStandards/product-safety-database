require "rails_helper"

RSpec.describe RiskLevelForm do
  subject(:form) { described_class.new(risk_level: risk_level, custom_risk_level: custom_risk_level) }

  let(:standard_level_key) { Investigation.risk_levels.keys.first }
  let(:standard_level_text) do
    I18n.t(".investigations.risk_level.show.levels.#{standard_level_key}")
  end

  describe "#initialize" do
    context "when risk level is not set" do
      let(:risk_level) { nil }

      context "with a custom risk level that does not match a standard level" do
        let(:custom_risk_level) { "very very risky" }

        it "sets risk level as 'other'" do
          expect(form.risk_level).to eq "other"
        end

        it "keeps custom risk level " do
          expect(form.custom_risk_level).to eq custom_risk_level
        end
      end

      context "with a custom risk level that matches with space/capital variations a standard level" do
        let(:custom_risk_level) { standard_level_text.upcase + "  " }

        it "sets risk level attribute as the standard level matching the custom risk level" do
          expect(form.risk_level).to eq standard_level_key
        end

        it "discards the value for custom risk level attribute" do
          expect(form.custom_risk_level).to be_nil
        end
      end
    end

    context "when risk level matches a standard level" do
      let(:risk_level) { standard_level_key }
      let(:custom_risk_level) { "whatever level" }

      it "keeps the value for risk level attribute" do
        expect(form.risk_level).to eq risk_level
      end

      it "discards the value for custom risk level attribute" do
        expect(form.custom_risk_level).to be_nil
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

      it "keeps the original custom_risk_level in the form" do
        form.validate
        expect(form.custom_risk_level).to eq custom_risk_level
      end
    end

    context "when neither the risk_level or the custom_risk_level are set" do
      let(:risk_level) { nil }
      let(:custom_risk_level) { nil }

      include_examples "valid form"
    end

    context "when risk level is set to any of the standard levels" do
      let(:risk_level) { standard_level_key }

      context "with custom risk level" do
        let(:custom_risk_level) { "custom risk" }

        include_examples "valid form"
      end

      context "without custom risk level" do
        let(:custom_risk_level) { nil }

        include_examples "valid form"
      end
    end

    context "when risk level is set to 'other'" do
      let(:risk_level) { "other" }

      context "with custom_risk_level" do
        let(:custom_risk_level) { "custom risk" }

        include_examples "valid form"
      end

      context "without custom_risk_level" do
        let(:custom_risk_level) { nil }

        include_examples "invalid form", [:custom_risk_level, "Set a risk level"]
      end
    end

    context "when risk level is set to a non allowed value" do
      let(:risk_level) { "random risk" }

      context "with custom_risk_level" do
        let(:custom_risk_level) { "custom risk" }

        include_examples "invalid form", [:risk_level, "Invalid option"]
      end

      context "without custom_risk_level" do
        let(:custom_risk_level) { nil }

        include_examples "invalid form", [:risk_level, "Invalid option"]
      end
    end
  end
end
