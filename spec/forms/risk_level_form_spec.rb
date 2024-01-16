RSpec.describe RiskLevelForm do
  subject(:form) { described_class.new(risk_level:) }

  let(:standard_level_key) { Investigation.risk_levels.keys.first }
  let(:standard_level_text) do
    I18n.t(".investigations.risk_level.show.levels.#{standard_level_key}")
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
    end

    context "when the risk_level is not set" do
      let(:risk_level) { nil }

      include_examples "valid form"
    end

    context "when risk level is set to any of the standard levels" do
      let(:risk_level) { standard_level_key }

      include_examples "valid form"
    end

    context "when risk level is set to a non allowed value" do
      let(:risk_level) { "random risk" }

      include_examples "invalid form", [:risk_level, "Risk level is not included in the list"]
    end
  end
end
