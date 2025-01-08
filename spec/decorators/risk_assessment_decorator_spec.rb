require "rails_helper"

RSpec.describe RiskAssessmentDecorator, :with_stubbed_opensearch do
  subject(:decorated_risk_assessment) { risk_assessment.decorate }

  let(:risk_assessment) { build(:risk_assessment) }

  describe "#case_id" do
    it "returns the investigation pretty id" do
      expect(decorated_risk_assessment.case_id).to eq(risk_assessment.investigation.pretty_id)
    end
  end
end
