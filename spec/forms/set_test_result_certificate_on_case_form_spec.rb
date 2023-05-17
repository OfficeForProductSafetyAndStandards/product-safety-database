require "rails_helper"

RSpec.describe SetTestResultCertificateOnCaseForm, type: :model do
  subject(:form) { described_class.new(params) }

  let(:tso_certificate_reference_number) { "abc123" }
  let(:tso_certificate_issue_date) do
    { day: "1", month: "2", year: "2020" }
  end
  let(:params) do
    {
      tso_certificate_reference_number:,
      tso_certificate_issue_date:
    }
  end

  describe "validations" do
    it "is valid with a valid setup" do
      expect(form).to be_valid
    end

    context "when tso_certificate_reference_number is missing" do
      let(:tso_certificate_reference_number) { nil }

      it "is valid" do
        expect(form).to be_valid
      end
    end

    it_behaves_like "it does not allow far away dates", :tso_certificate_issue_date, nil, on_or_before: false

    context "when tso_certificate_issue_date is missing" do
      let(:tso_certificate_issue_date) { { day: '', month: '', year: ''} }

      it "is invalid with an invalid type" do
        expect(form).not_to be_valid
        expect(form.errors[:tso_certificate_issue_date]).to include("Enter the date the test certificate was issued")
      end
    end
  end
end
