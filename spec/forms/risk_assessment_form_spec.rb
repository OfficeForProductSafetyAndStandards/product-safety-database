require "rails_helper"

RSpec.describe RiskAssessmentForm, :with_stubbed_elasticsearch, :with_test_queue_adapter do
  # Default set of valid attributes
  let(:investigation) { create(:allegation) }
  let(:user) { create(:user) }

  let(:assessment_date) { { day: "1", month: "2", year: "2020" } }
  let(:assessed_by) { "another_team" }
  let(:assessed_by_team_id) { create(:team).id }
  let(:assessed_by_business_id) { "" }
  let(:assessed_by_other) { "" }

  let(:risk_level) { "serious" }
  let(:custom_risk_level) { "" }
  let(:product_ids) { [create(:product).id] }
  let(:details) { "" }
  let(:old_file) { nil }
  let(:risk_assessment_file) { Rack::Test::UploadedFile.new("test/fixtures/files/test_result.txt") }

  let(:form) do
    described_class.new(
      investigation: investigation,
      current_user: user,
      assessed_on: assessment_date,
      assessed_by: assessed_by,
      assessed_by_team_id: assessed_by_team_id,
      assessed_by_business_id: assessed_by_business_id,
      assessed_by_other: assessed_by_other,
      risk_level: risk_level,
      custom_risk_level: custom_risk_level,
      product_ids: product_ids,
      old_file: old_file,
      risk_assessment_file: risk_assessment_file,
      details: details
    )
  end

  describe "validations" do
    context "with valid attributes" do
      it "is valid" do
        expect(form).to be_valid
      end
    end

    # Risk levels
    context "with a custom risk level specified" do
      let(:risk_level) { "other" }
      let(:custom_risk_level) { "Semi-serious risk" }

      it "is valid" do
        expect(form).to be_valid
      end
    end

    context "with a 'other' risk level but no custom risk level given" do
      let(:risk_level) { "other" }
      let(:custom_risk_level) { "" }

      it "is not valid" do
        expect(form).not_to be_valid
      end
    end

    context "with no risk level specified" do
      let(:risk_level) { "" }
      let(:custom_risk_level) { "" }

      it "is not valid" do
        expect(form).not_to be_valid
      end
    end

    # Assessment date
    context "with no assessment date specified" do
      let(:assessment_date) { { day: "", month: "", year: "" } }

      it "is not valid" do
        expect(form).not_to be_valid
      end
    end

    context "with a partial assessment date" do
      let(:assessment_date) { { day: "1", month: "12", year: "" } }

      it "is not valid" do
        expect(form).not_to be_valid
      end
    end

    context "with an assessment date that isn't a real date" do
      let(:assessment_date) { { day: "99", month: "12", year: "2020" } }

      it "is not valid" do
        expect(form).not_to be_valid
      end
    end

    context "with an assessment date that isn't numerical" do
      let(:assessment_date) { { day: "x", month: "12", year: "2020" } }

      it "is not valid" do
        expect(form).not_to be_valid
      end
    end

    context "with an assessment date that is in the future" do
      let(:assessment_date) { { day: "1", month: "1", year: "2050" } }

      it "is not valid" do
        expect(form).not_to be_valid
      end
    end

    context "with an assessment date that is before 1970" do
      let(:assessment_date) { { day: "31", month: "12", year: "1969" } }

      it "is not valid" do
        expect(form).not_to be_valid
      end
    end

    # Assessed by

    context "with no 'assessed by' option specified" do
      let(:assessed_by) { "" }

      it "is not valid" do
        expect(form).not_to be_valid
      end
    end

    context "with 'assessed by' as 'my_team'" do
      let(:assessed_by) { "my_team" }

      it "is valid" do
        expect(form).to be_valid
      end
    end

    context "with 'assessed by' as another_team but no team_id specified" do
      let(:assessed_by) { "another_team" }
      let(:assessed_by_team_id) { "" }

      it "is not valid" do
        expect(form).not_to be_valid
      end
    end

    context "with 'assessed by' as another_team and a team_id specified" do
      let(:assessed_by) { "another_team" }
      let(:assessed_by_team_id) { create(:team).id.to_s }

      it "is valid" do
        expect(form).to be_valid
      end
    end

    context "with 'assessed by' as a business but no business_id specified" do
      let(:assessed_by) { "business" }
      let(:assessed_by_business_id) { "" }

      it "is not valid" do
        expect(form).not_to be_valid
      end
    end

    context "with 'assessed by' as a business and a business_id specified" do
      let(:assessed_by) { "business" }
      let(:assessed_by_business_id) { create(:business).id }

      it "is valid" do
        expect(form).to be_valid
      end
    end

    context "with 'assessed by' as 'other' but no other organisation specified" do
      let(:assessed_by) { "other" }
      let(:assessed_by_other) { "" }

      it "is not valid" do
        expect(form).not_to be_valid
      end
    end

    context "with 'assessed by' as 'other' and another organisation specified" do
      let(:assessed_by) { "other" }
      let(:assessed_by_other) { "RiskAssessmentsRUS" }

      it "is valid" do
        expect(form).to be_valid
      end
    end

    # Products
    context "with no product_ids specified" do
      let(:product_ids) { [] }

      it "is not valid" do
        expect(form).not_to be_valid
      end
    end

    context "with no risk_assessment_file" do
      let(:risk_assessment_file) { nil }

      context "when old_file is not present" do
        it "is not valid" do
          expect(form).not_to be_valid
        end
      end

      context "when old_file is present" do
        let(:old_file) { Rack::Test::UploadedFile.new("test/fixtures/files/test_result.txt") }

        it "is valid" do
          expect(form).to be_valid
        end
      end
    end
  end

  describe "attributes" do
    describe "#custom_risk_level" do
      let(:custom_risk_level) { "Medium risk" }

      context "when risk_level is set to :other" do
        let(:risk_level) { :other }

        it "returns the value set" do
          expect(form.custom_risk_level).to eq "Medium risk"
        end
      end

      context "when risk_level is not set to :other" do
        let(:risk_level) { :serious }

        it "always returns nil" do
          expect(form.custom_risk_level).to be nil
        end
      end
    end

    describe "#assessed_by_business_id" do
      let(:assessed_by_business_id) { "123" }

      context "when assessed_by is set to 'business'" do
        let(:assessed_by) { "business" }

        it "returns the value set" do
          expect(form.assessed_by_business_id).to eq "123"
        end
      end

      context "when assessed_by is set another option" do
        let(:assessed_by) { "my_team" }

        it "always returns nil" do
          expect(form.assessed_by_business_id).to be nil
        end
      end
    end

    describe "#assessed_by_team_id" do
      let(:assessed_by_team_id) { "123" }

      context "when assessed_by is set to 'another_team'" do
        let(:assessed_by) { "another_team" }

        it "returns the value set" do
          expect(form.assessed_by_team_id).to eq "123"
        end
      end

      context "when assessed_by is set another option" do
        let(:assessed_by) { "business" }

        it "always returns nil" do
          expect(form.assessed_by_team_id).to be nil
        end
      end
    end

    describe "#assessed_by_other" do
      let(:assessed_by_other) { "Another Org Ltd" }

      context "when assessed_by is set to 'other'" do
        let(:assessed_by) { "other" }

        it "returns the value set" do
          expect(form.assessed_by_other).to eq "Another Org Ltd"
        end
      end

      context "when assessed_by is set another option" do
        let(:assessed_by) { "business" }

        it "always returns nil" do
          expect(form.assessed_by_other).to be nil
        end
      end
    end
  end
end
