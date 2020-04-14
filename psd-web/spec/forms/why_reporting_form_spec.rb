require "rails_helper"

RSpec.describe WhyReportingForm do
  subject(:form) { described_class.new(why_reporrting_form) }

  let(:reported_reason_unsafe) { nil }
  let(:reported_reason_non_compliant) { nil }
  let(:reported_reason_safe_and_compliant) { nil }

  describe "validations" do

  end

  describe "#reported_reason" do
    context "when setting only unsafe to true" do
      let(:why_reporrting_form) { { reported_reason_unsafe: true } }

      it { expect(form.reported_reason).to eq(:unsafe) }
    end

    context "when setting only non_compliant to true" do
      let(:why_reporrting_form) { { reported_reason_non_compliant: true } }

      it { expect(form.reported_reason).to eq(:non_compliant) }
    end

    context "when setting only safe_and_compliant to true" do
      let(:why_reporrting_form) { { reported_reason_safe_and_compliant: true } }

      it { expect(form.reported_reason).to eq(:safe_and_compliant) }
    end

    context "when not setting any reported_reason properties to true" do
      it { expect(form.reported_reason).to be nil }
    end
  end
end
