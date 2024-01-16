RSpec.describe ChangeCaseVisibilityForm, :with_test_queue_adapter do
  subject(:form) { described_class.from(investigation) }

  let(:investigation) { build(:allegation) }

  describe ".from" do
    it "sets the case type" do
      expect(form.case_type).to eq("notification")
    end

    it "sets the old visibility" do
      expect(form.old_visibility).to eq("unrestricted")
    end
  end

  describe "#valid?" do
    context "without new_visibility" do
      it "returns false" do
        expect(form).to be_invalid
      end
    end

    context "with new_visibility the same as old_visibility" do
      before { form.new_visibility = "unrestricted" }

      it "returns false" do
        expect(form).to be_invalid
      end
    end

    context "with new_visibility an invalid value" do
      before { form.new_visibility = "invalid" }

      it "returns false" do
        expect(form).to be_invalid
      end
    end

    context "with new_visibility different to old_visibility" do
      before { form.new_visibility = "restricted" }

      it "returns false" do
        expect(form).to be_valid
      end
    end
  end
end
