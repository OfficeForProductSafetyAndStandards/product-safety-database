require "rails_helper"

RSpec.describe ChangeCaseSummaryForm do
  subject(:form) { described_class.new(summary: summary) }

  let(:summary) { "New summary" }

  describe "#valid?" do
    it "is valid" do
      expect(form).to be_valid
    end

    it "does not contain error messages" do
      form.validate
      expect(form.errors).to be_empty
    end

    shared_examples_for "invalid form" do |*errors|
      it "is not valid" do
        expect(form).to be_invalid
      end

      it "populates an error message" do
        form.validate
        errors.each do |property, message|
          expect(form.errors.full_messages_for(property)).to eq([message])
        end
      end
    end

    context "when no summary is supplied" do
      let(:summary) { " " }

      include_examples "invalid form", [:summary, "Enter the case summary"]
    end

    context "when summary is too long" do
      let(:summary) { rand(36**20_000).to_s(36) }

      include_examples "invalid form", [:summary, "Summary must be 10,000 characters or fewer"]
    end
  end
end
