require "rails_helper"

RSpec.describe AccidentOrIncidentTypeForm, :with_stubbed_elasticsearch, :with_test_queue_adapter do
  # Default set of valid attributes
  let(:event_type) { "accident" }
  let(:params) do
    {
      event_type: event_type
    }
  end

  let(:form) { described_class.new(params) }

  describe "validations" do
    context "with valid attributes" do
      let(:event_type) { "accident" }

      it "is valid" do
        expect(form).to be_valid
      end
    end

    context "when missing event_type" do
      let(:event_type) { nil }

      it "is not valid" do
        expect(form).not_to be_valid
      end
    end

    context "when event_type is not `accident` or `incident`" do
      let(:event_type) { "disaster" }

      it "is not valid" do
        expect(form).not_to be_valid
      end
    end
  end
end
