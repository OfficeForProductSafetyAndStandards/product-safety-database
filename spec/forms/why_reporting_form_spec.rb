RSpec.describe WhyReportingForm do
  subject(:form) { described_class.new(why_reporting_params) }

  let(:reported_reason_unsafe) { nil }
  let(:reported_reason_non_compliant) { nil }
  let(:reported_reason_safe_and_compliant) { nil }

  describe "validates the options are mututally exclusive" do
    context "when no option is set" do
      let(:why_reporting_params) { {} }

      it "is invalid", :aggregate_failures do
        expect(form).to be_invalid

        expect(form.errors.full_messages_for(:base)).to eq(["Choose at least one option"])
      end
    end

    context "when only one option is set" do
      let(:why_reporting_params) do
        {
          reported_reason_unsafe: true,
          hazard_type: Rails.application.config.hazard_constants["hazard_type"].sample,
          hazard_description: Faker::Hipster.sentence
        }
      end

      it { is_expected.to be_valid }
    end
  end

  describe "#validates unsafe" do
    let(:hazard_type)          { Faker::Hipster.word }
    let(:hazard_description)   { Faker::Hipster.sentence }
    let(:why_reporting_params) do
      {
        reported_reason_unsafe: true,
        hazard_type:,
        hazard_description:
      }
    end

    context "when reporting unsafe" do
      context "when the hazard type is empty", :aggregate_failures do
        let(:hazard_type) { "" }

        it "is not valid and has an error" do
          expect(form).to be_invalid

          expect(form.errors.full_messages_for(:hazard_type)).to eq(["Enter the primary hazard"])
        end
      end

      context "when the hazard description is empty" do
        let(:hazard_description) { "" }

        it "is not valid and has an error", :aggregate_failures do
          expect(form).to be_invalid
          expect(form.errors.full_messages_for(:hazard_description)).to eq(["Hazard description cannot be blank"])
        end
      end
    end
  end

  describe "#validates non compiance reason" do
    let(:why_reporting_params) do
      {
        reported_reason_non_compliant: true,
        non_compliant_reason:
      }
    end

    context "when non compliant is checked" do
      let(:non_compliant_reason) { nil }

      context "when no non compliance reason is provided" do
        it "is invalid", :aggregate_failures do
          expect(form).to be_invalid

          expect(form.errors.full_messages_for(:reported_reason_non_compliant)).to be_empty
          expect(form.errors.full_messages_for(:non_compliant_reason)).to eq(["Non compliant reason cannot be blank"])
        end
      end

      context "when a non compliance reason is provided" do
        let(:non_compliant_reason) { Faker::Lorem.sentence }

        it "is invalid", :aggregate_failures do
          expect(form).to be_valid

          expect(form.errors.full_messages_for(:reported_reason_non_compliant)).to be_empty
          expect(form.errors.full_messages_for(:non_compliant_reason)).to be_empty
        end
      end
    end
  end

  describe "#assign_to" do
    let(:investigation)        { build(:project) }
    let(:hazard_type)          { Faker::Lorem.word }
    let(:hazard_description)   { Faker::Lorem.paragraph }
    let(:non_compliant_reason) { Faker::Lorem.paragraph }
    let(:why_reporting_params) do
      {
        hazard_type:,
        hazard_description:,
        non_compliant_reason:
      }
    end
    let(:expected_assigned_attributes) do
      {
        reported_reason:,
        hazard_type:,
        hazard_description:,
        non_compliant_reason:,
      }
    end

    shared_examples "assigns the correct attributes to the investigation" do
      it "assign all the relevant attributes to the investigation", :aggregate_failures do
        expect(form).to be_valid
        form.assign_to(investigation)

        expect(investigation).to have_attributes(expected_assigned_attributes)
      end
    end

    context "when reporting unsafe" do
      let(:reported_reason) { Investigation.reported_reasons[:unsafe] }

      before { why_reporting_params[:reported_reason_unsafe] = true }

      it_behaves_like "assigns the correct attributes to the investigation"
    end

    context "when reporting non compliant to" do
      let(:reported_reason) { Investigation.reported_reasons[:non_compliant] }

      before { why_reporting_params[:reported_reason_non_compliant] = true }

      it_behaves_like "assigns the correct attributes to the investigation"
    end

    context "when reporting unsafe and non compliant" do
      let(:reported_reason) { Investigation.reported_reasons[:unsafe_and_non_compliant] }

      before do
        why_reporting_params[:reported_reason_unsafe]        = true
        why_reporting_params[:reported_reason_non_compliant] = true
      end

      it_behaves_like "assigns the correct attributes to the investigation"
    end

    context "when reporting safe and compliant" do
      let(:reported_reason) { Investigation.reported_reasons[:safe_and_compliant] }

      before { why_reporting_params[:reported_reason_safe_and_compliant] = true }

      it_behaves_like "assigns the correct attributes to the investigation"
    end
  end
end
