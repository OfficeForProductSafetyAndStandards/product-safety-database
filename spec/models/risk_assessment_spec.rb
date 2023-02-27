require "rails_helper"

RSpec.describe RiskAssessment, type: :model do
  describe "validations", :aggregate_failures do
    let(:risk_assessment) do
      described_class.new(
        investigation:,
        risk_level:,
        custom_risk_level:,
        investigation_products:,
        added_by_user:,
        added_by_team:,
        assessed_by_team:,
        assessed_by_business:,
        assessed_by_other:,
        assessed_on: assessment_date
      )
    end

    # Default set of valid attributes
    let(:investigation) { build(:allegation) }
    let(:added_by_user) { build(:user) }
    let(:added_by_team) { build(:team) }
    let(:assessed_by_team) { build(:team) }
    let(:assessed_by_business) { nil }
    let(:assessed_by_other) { nil }
    let(:assessment_date) { Time.zone.today }
    let(:risk_level) { "serious" }
    let(:custom_risk_level) { nil }
    let(:investigation_products) { [build(:investigation_product)] }

    context "with all required attributes" do
      it "is valid" do
        expect(risk_assessment).to be_valid
      end
    end

    context "with no risk_level" do
      let(:risk_level) { nil }

      it "is not valid", :aggregate_failures do
        expect(risk_assessment).not_to be_valid
        expect(risk_assessment.errors.details[:risk_level]).to eql([{ error: :blank }])
      end
    end

    context "with a risk_level AND a custom risk level" do
      let(:risk_level) { "serious" }
      let(:custom_risk_level) { "not serious" }

      it "is not valid" do
        expect(risk_assessment).not_to be_valid
        expect(risk_assessment.errors.details[:custom_risk_level]).to eql([{ error: :present }])
      end
    end

    context "with no investigation associated" do
      let(:investigation) { nil }

      it "is not valid" do
        expect(risk_assessment).not_to be_valid
        expect(risk_assessment.errors.details[:investigation]).to eql([{ error: :blank }])
      end
    end

    context "with no user who added it associated" do
      let(:added_by_user) { nil }

      it "is not valid" do
        expect(risk_assessment).not_to be_valid
        expect(risk_assessment.errors.details[:added_by_user]).to eql([{ error: :blank }])
      end
    end

    context "with no team who added it associated" do
      let(:added_by_team) { nil }

      it "is not valid" do
        expect(risk_assessment).not_to be_valid
        expect(risk_assessment.errors.details[:added_by_team]).to eql([{ error: :blank }])
      end
    end

    context "with no team or business or other who assessed it" do
      let(:assessed_by_team) { nil }
      let(:assessed_by_business) { nil }
      let(:assessed_by_other) { nil }

      it "is not valid" do
        expect(risk_assessment).not_to be_valid
        expect(risk_assessment.errors.details[:assessed_by_other]).to eql([{ error: :blank }])
      end
    end

    context "with a team AND a business who assessed it" do
      let(:assessed_by_team) { build(:team) }
      let(:assessed_by_business) { build(:business) }
      let(:assessed_by_other) { nil }

      it "is not valid" do
        expect(risk_assessment).not_to be_valid
        expect(risk_assessment.errors.details[:assessed_by_business]).to eql([{ error: :present }])
      end
    end

    context "with a team AND an 'other' value who assessed it" do
      let(:assessed_by_team) { build(:team) }
      let(:assessed_by_business) { nil }
      let(:assessed_by_other) { "AssessmentsRUs" }

      it "is not valid" do
        expect(risk_assessment).not_to be_valid
        expect(risk_assessment.errors.details[:assessed_by_other]).to eql([{ error: :present }])
      end
    end

    context "with a business AND an 'other' value who assessed it" do
      let(:assessed_by_team) { nil }
      let(:assessed_by_business) { build(:business) }
      let(:assessed_by_other) { "AssessmentsRUs" }

      it "is not valid" do
        expect(risk_assessment).not_to be_valid
        expect(risk_assessment.errors.details[:assessed_by_other]).to eql([{ error: :present }])
      end
    end

    context "with no associated products" do
      let(:investigation_products) { [] }

      it "is not valid" do
        expect(risk_assessment).not_to be_valid
        expect(risk_assessment.errors.details[:products]).to eql([{ error: :blank }])
      end
    end

    context "with no assessment date" do
      let(:assessment_date) { nil }

      it "is not valid" do
        expect(risk_assessment).not_to be_valid
        expect(risk_assessment.errors.details[:assessed_on]).to eql([{ error: :blank }])
      end
    end

    context "with as assessment date in the future" do
      let(:assessment_date) { Time.zone.today + 2.days }

      it "is not valid" do
        expect(risk_assessment).not_to be_valid
        expect(risk_assessment.errors.details[:assessed_on]).to eql([{ error: :in_future }])
      end
    end

    context "with as assessment date before 1 Jan 1970" do
      let(:assessment_date) { Date.new(1969, 12, 31) }

      it "is not valid" do
        expect(risk_assessment).not_to be_valid
        expect(risk_assessment.errors.details[:assessed_on]).to eql([{ error: :too_old }])
      end
    end
  end
end
