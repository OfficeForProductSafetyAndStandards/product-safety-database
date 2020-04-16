require "rails_helper"

RSpec.describe WhyReportingForm do
  subject(:form) { described_class.new(why_reporting_params) }

  let(:reported_reason_unsafe) { nil }
  let(:reported_reason_non_compliant) { nil }
  let(:reported_reason_safe_and_compliant) { nil }

  describe "validates the options are mututally exclusive" do
    context "when only option is set" do
      let(:why_reporting_params) { { reported_reason_unsafe: true } }

      it { is_expected.to be_valid }
    end

    context "when two mutually exclusive options are set" do
      let(:why_reporting_params) do
        { reported_reason_safe_and_compliant: true, reported_reason_non_compliant: true }
      end

      it "is invalid and sets and error", :aggregate_failures do
        expect(form).to be_invalid
        expect(form.errors[:reported_reason_safe_and_compliant]).to eq(["Select only one answer"])
        expect(form.errors[:reported_reason_non_compliant]).to eq(["Select only one answer"])
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
        hazard_type:                   hazard_type,
        hazard_description:            hazard_description,
        non_compliant_reason:          non_compliant_reason
      }
    end
    let(:expected_assigned_attributes) do
      {
        reported_reason:      reported_reason,
        hazard_type:          hazard_type,
        hazard_description:   hazard_description,
        non_compliant_reason: non_compliant_reason,
        description:          description
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
      let(:description)     { "Product reported because it is unsafe." }

      before { why_reporting_params[:reported_reason_unsafe] = true }

      it_behaves_like "assigns the correct attributes to the investigation"
    end

    context "when reporting non compliant to" do
      let(:reported_reason) { Investigation.reported_reasons[:non_compliant] }
      let(:description) { "Product reported because it is non-compliant." }

      before { why_reporting_params[:reported_reason_non_compliant] = true }

      it_behaves_like "assigns the correct attributes to the investigation"
    end

    context "when reporting unsafe and non compliant" do
      let(:reported_reason) { Investigation.reported_reasons[:unsafe_and_non_compliant] }
      let(:description) { "Product reported because it is unsafe and non-compliant." }

      before do
        why_reporting_params[:reported_reason_unsafe]        = true
        why_reporting_params[:reported_reason_non_compliant] = true
      end

      it_behaves_like "assigns the correct attributes to the investigation"
    end

    context "when reporting safe and compliant" do
      let(:reported_reason) { Investigation.reported_reasons[:safe_and_compliant] }
      let(:description) { "Product reported because it is safe and compliant." }

      before { why_reporting_params[:reported_reason_safe_and_compliant] = true }

      it_behaves_like "assigns the correct attributes to the investigation"
    end
  end
end
