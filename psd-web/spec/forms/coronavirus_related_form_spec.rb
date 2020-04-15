require "rails_helper"

RSpec.describe CoronavirusRelatedForm do
  subject(:form) { described_class.new(coronavirus_related: coronavirus_related) }

  describe "#valid?" do
    before { form.validate }

    describe "when the coronavirus option is not selected" do
      let(:coronavirus_related) { nil }

      it "is not valid" do
        expect(form).to be_invalid
      end

      it "populates an error message" do
        expect(form.errors.full_messages_for(:coronavirus_related)).to eq(["Select whether or not the case is related to the coronavirus outbreak"])
      end
    end

    context "when the coronavirus option is selected" do
      let(:coronavirus_related) { "true" }

      it "is is valid" do
        expect(form).to be_valid
      end

      it "does not contain error messages" do
        expect(form.errors.full_messages_for(:coronavirus_related)).to be_empty
      end
    end
  end
end
