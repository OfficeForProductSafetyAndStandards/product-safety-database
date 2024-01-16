RSpec.describe AccidentOrIncidentTypeForm, :with_test_queue_adapter do
  # Default set of valid attributes
  let(:type) { "Accident" }
  let(:params) do
    {
      type:
    }
  end

  let(:form) { described_class.new(params) }

  describe "validations" do
    context "with valid attributes" do
      let(:type) { "Accident" }

      it "is valid" do
        expect(form).to be_valid
      end
    end

    context "when missing type" do
      let(:type) { nil }

      it "is not valid" do
        expect(form).not_to be_valid
      end
    end

    context "when type is not `accident` or `incident`" do
      let(:type) { "disaster" }

      it "is not valid" do
        expect(form).not_to be_valid
      end
    end
  end
end
