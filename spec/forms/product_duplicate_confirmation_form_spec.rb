require "rails_helper"

RSpec.describe ProductDuplicateConfirmationForm do
  subject(:form) { described_class.new(params) }

  let(:params) { {} }

  context "when correct is not provided" do
    it { is_expected.not_to be_valid }
  end

  context "when correct=true is provided" do
    let(:params) { { correct: "yes" } }

    it { is_expected.to be_valid }
  end

  context "when correct=false is provided" do
    let(:params) { { correct: "no" } }

    it { is_expected.to be_valid }
  end

  context "when correct=invalid is provided" do
    let(:params) { { correct: "invalid" } }

    it { is_expected.not_to be_valid }
  end

  describe "#correct?" do
    context "when correct is true" do
      let(:params) { { correct: "yes" } }

      it "returns true" do
        expect(form.correct?).to be true
      end
    end

    context "when correct is false" do
      let(:params) { { correct: "no" } }

      it "returns false" do
        expect(form.correct?).to be false
      end
    end
  end
end
