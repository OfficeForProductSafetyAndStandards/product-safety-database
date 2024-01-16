RSpec.describe ChangeNotificationSummaryForm do
  subject(:form) { described_class.new(summary:) }

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

      it "is valid" do
        expect(form).to be_valid
      end

      it "does not contain error messages" do
        form.validate
        expect(form.errors).to be_empty
      end
    end

    context "when summary is too long" do
      let(:summary) { rand(36**20_000).to_s(36) }

      include_examples "invalid form", [:summary, "Summary is too long (maximum is 10000 characters)"]
    end
  end
end
