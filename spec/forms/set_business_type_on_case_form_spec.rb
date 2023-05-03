require "rails_helper"

RSpec.describe SetBusinessTypeOnCaseForm, type: :model do
  subject(:form) { described_class.new(params) }

  let(:type) { "retailer" }
  let(:params) do
    {
      type:
    }
  end

  describe "validations" do
    it "is valid with a valid type" do
      expect(form).to be_valid
    end

    context "when type is missing" do
      let(:type) { nil }

      it "is invalid with an invalid type" do
        expect(form).not_to be_valid
        expect(form.errors[:type]).to include("Select a business type")
      end
    end

    context "when type is not in the list" do
      let(:type) { "invalid" }

      it "is invalid with an invalid type" do
        expect(form).not_to be_valid
        expect(form.errors[:type]).to include("Select a business type")
      end
    end
  end
end
