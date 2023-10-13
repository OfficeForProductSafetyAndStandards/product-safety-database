require "rails_helper"

RSpec.describe InvestigationSerializer, :with_stubbed_mailer, :with_test_queue_adapter, type: :serializers do
  subject { described_class.new(investigation) }

  let(:investigation) { create(:allegation) }

  context "with an investigation" do
    let(:hash) { subject.to_h }

    it "serializes the investigation object", :aggregate_failures do
      expect(hash[:type]).to eq(investigation.type)
      expect(hash[:hazard_type]).to eq(investigation.hazard_type)
      expect(hash[:user_title]).to eq(investigation.user_title)
    end
  end
end
