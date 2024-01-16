RSpec.describe SetTestResultFundingOnCaseForm, type: :model do
  subject(:form) { described_class.new(params) }

  let(:opss_funded) { "true" }
  let(:params) do
    {
      opss_funded:
    }
  end

  describe "validations" do
    it "is valid with a valid type" do
      expect(form).to be_valid
    end

    context "when opss_funded is missing" do
      let(:opss_funded) { nil }

      it "is invalid with an invalid type" do
        expect(form).not_to be_valid
        expect(form.errors[:opss_funded]).to include("Select yes if the test was funded under the OPSS Sampling Protocol")
      end
    end

    context "when opss_funded is not in the list" do
      let(:opss_funded) { "invalid" }

      it "is invalid with an invalid type" do
        expect(form).not_to be_valid
        expect(form.errors[:opss_funded]).to include("Select yes if the test was funded under the OPSS Sampling Protocol")
      end
    end
  end
end
