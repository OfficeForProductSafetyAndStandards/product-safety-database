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

  describe "#reported_reason" do
    context "when setting only unsafe to true" do
      let(:why_reporting_params) { { reported_reason_unsafe: true } }

      it { expect(form.reported_reason).to eq(Investigation.reported_reasons[:unsafe]) }
    end

    context "when setting only non_compliant to true" do
      let(:why_reporting_params) { { reported_reason_non_compliant: true } }

      it { expect(form.reported_reason).to eq(Investigation.reported_reasons[:non_compliant]) }
    end

    context "when setting unsafe and non_compliant to true" do
      let(:why_reporting_params) { { reported_reason_unsafe: true, reported_reason_non_compliant: true } }

      it { expect(form.reported_reason).to eq(Investigation.reported_reasons[:unsafe_and_non_compliant]) }
    end

    context "when setting only safe_and_compliant to true" do
      let(:why_reporting_params) { { reported_reason_safe_and_compliant: true } }

      it { expect(form.reported_reason).to eq(Investigation.reported_reasons[:safe_and_compliant]) }
    end

    context "when not setting any reported_reason properties to true" do
      let(:form) { described_class.new }

      it { expect(form.reported_reason).to be nil }
    end
  end

  describe "#assign_to" do
    let(:investigation)        { build(:project) }
    let(:hazard_type)          { Faker::Lorem.word }
    let(:hazard_description)   { Faker::Lorem.paragraph }
    let(:non_compliant_reason) { Faker::Lorem.paragraph }
    let(:why_reporting_params) do
      {
        reported_reason_unsafe: true,
        reported_reason_non_compliant: true,
        hazard_type: hazard_type,
        hazard_description: hazard_description,
        non_compliant_reason: non_compliant_reason
      }
    end
    let(:expected_assigned_attributes) do
      {
        reported_reason: Investigation.reported_reasons[:unsafe_and_non_compliant],
        hazard_type: hazard_type,
        hazard_description: hazard_description,
        non_compliant_reason: non_compliant_reason
      }
    end

    it "assign all the relevant attributes to the investigation", :aggregate_failures do
      expect(form).to be_valid
      form.assign_to(investigation)

      expect(investigation).to have_attributes(expected_assigned_attributes)
    end
  end
end
