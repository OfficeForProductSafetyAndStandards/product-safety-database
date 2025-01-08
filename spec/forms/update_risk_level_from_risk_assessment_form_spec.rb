require "rails_helper"

RSpec.describe UpdateRiskLevelFromRiskAssessmentForm do
  describe "update case risk level to match risk assessment validation" do
    let(:form) { described_class.new(update_case_risk_level_to_match_investigation: answer) }

    context "when answered with 'Yes...'" do
      let(:answer) { "true" }

      it "is valid" do
        expect(form).to be_valid
      end
    end

    context "when answered with 'No..'" do
      let(:answer) { "false" }

      it "is valid" do
        expect(form).to be_valid
      end
    end

    context "when not answered" do
      let(:answer) { "" }

      it "is not valid" do
        expect(form).not_to be_valid
      end
    end
  end
end
