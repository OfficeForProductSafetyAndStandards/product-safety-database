require "rails_helper"

RSpec.describe RiskAssessmentForm, :with_test_queue_adapter do
  # Default set of valid attributes
  let(:investigation) { create(:allegation) }
  let(:user) { create(:user) }

  let(:assessment_date) { { day: "1", month: "2", year: "2020" } }
  let(:assessed_by) { "another_team" }
  let(:assessed_by_team_id) { create(:team).id }
  let(:assessed_by_business_id) { "" }
  let(:assessed_by_other) { "" }

  let(:risk_level) { "serious" }
  let(:investigation_product_ids) { [create(:investigation_product).id] }
  let(:details) { "" }
  let(:old_file) { nil }
  let(:risk_assessment_file) { Rack::Test::UploadedFile.new("test/fixtures/files/test_result.txt") }

  let(:params) do
    {
      investigation:,
      current_user: user,
      assessed_on: assessment_date,
      assessed_by:,
      assessed_by_team_id:,
      assessed_by_business_id:,
      assessed_by_other:,
      risk_level:,
      investigation_product_ids:,
      old_file:,
      risk_assessment_file:,
      details:,
      "assessed_on(1i)" => 2020,
      "assessed_on(2i)" => 2,
      "assessed_on(3i)" => 1
    }
  end

  let(:form) { described_class.new(params) }

  describe "validations" do
    context "with valid attributes" do
      it "is valid" do
        expect(form).to be_valid
      end
    end

    # Risk levels
    context "with no risk level specified" do
      let(:risk_level) { "" }

      it "is not valid" do
        expect(form).not_to be_valid
      end
    end

    # Assessment date
    it_behaves_like "it does not allow an incomplete", :assessment_date, :assessed_on
    it_behaves_like "it does not allow malformed dates", :assessment_date, :assessed_on
    it_behaves_like "it does not allow dates in the future", :assessment_date, :assessed_on
    it_behaves_like "it does not allow far away dates", :assessment_date, :assessed_on, on_or_before: false

    context "with an assessment date that isn't numerical" do
      let(:assessment_date) { { day: "x", month: "12", year: "2020" } }

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

    context "with no investigation_product_ids specified" do
      let(:investigation_product_ids) { [] }

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
          expect(form.assessed_by_business_id).to be_nil
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
          expect(form.assessed_by_team_id).to be_nil
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
          expect(form.assessed_by_other).to be_nil
        end
      end
    end
  end

  describe "#cache_file!" do
    context "when a transcript file is not provided" do
      let(:risk_assessment_file) { nil }

      it "does not create a blob" do
        expect { form.cache_file! }.not_to change(ActiveStorage::Blob, :count)
      end
    end

    context "when a transcript file is provided" do
      it "does not create a blob" do
        expect { form.cache_file! }.to change(ActiveStorage::Blob, :count).by(1)
      end

      it "set existing_transcript_file_id" do
        expect { form.cache_file! }.to change(form, :existing_risk_assessment_file_file_id).from(nil).to(instance_of(String))
      end
    end
  end

  describe "#load_transcript_file" do
    let(:previous_form) do
      described_class.new(params.merge(risk_assessment_file: Rack::Test::UploadedFile.new(file_fixture("risk_assessment.txt"))))
    end

    before { previous_form.cache_file! }

    context "when no transcript is uploaded" do
      let(:risk_assessment_file) { nil }

      it "does not set the transcript" do
        expect { form.load_risk_assessment_file }.not_to change(form, :risk_assessment_file)
      end

      context "when no new transcript has been uploaded" do
        before do
          params[:existing_risk_assessment_file_file_id] = previous_form.existing_risk_assessment_file_file_id
        end

        it "loads the file blob" do
          expect { form.load_risk_assessment_file }
            .to change(form, :risk_assessment_file).from(nil).to(instance_of(ActiveStorage::Blob))
        end
      end
    end
  end
end
