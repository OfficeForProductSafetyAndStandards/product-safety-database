require "rails_helper"

RSpec.describe ChangeCaseStatusForm, :with_test_queue_adapter do
  subject(:form) { described_class.from(investigation) }

  let(:investigation) { build(:allegation) }

  describe ".from" do
    it "sets the case type" do
      expect(form.case_type).to eq("case")
    end

    it "sets the old status" do
      expect(form.old_status).to eq("open")
    end
  end

  describe "#valid?" do
    context "without new_status" do
      it "returns false" do
        expect(form).to be_invalid
      end
    end

    context "with new_status the same as old_status" do
      before { form.new_status = "open" }

      it "returns false" do
        expect(form).to be_invalid
      end
    end

    context "with new_status an invalid value" do
      before { form.new_status = "invalid" }

      it "returns false" do
        expect(form).to be_invalid
      end
    end

    context "with new_status different to old_status" do
      before { form.new_status = "closed" }

      it "returns false" do
        expect(form).to be_valid
      end
    end
  end
end
