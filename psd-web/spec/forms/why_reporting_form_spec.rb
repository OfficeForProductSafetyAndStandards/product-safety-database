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

      it { expect(form.reported_reason).to eq(:unsafe) }
    end

    context "when setting only non_compliant to true" do
      let(:why_reporting_params) { { reported_reason_non_compliant: true } }

      it { expect(form.reported_reason).to eq(:non_compliant) }
    end

    context "when setting only safe_and_compliant to true" do
      let(:why_reporting_params) { { reported_reason_safe_and_compliant: true } }

      it { expect(form.reported_reason).to eq(:safe_and_compliant) }
    end

    context "when not setting any reported_reason properties to true" do
      let(:form) { described_class.new }

      it { expect(form.reported_reason).to be nil }
    end
  end
end
