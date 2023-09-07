require "rails_helper"

RSpec.describe BusinessSerializer, type: :serializers do
  subject { described_class.new(business) }

  let(:business) { create(:business) }

  context "with a business" do
    let(:hash) { subject.to_h }

    it "serializes the business object", :aggregate_failures do
      expect(hash[:company_number]).to eq(business.company_number)
      expect(hash[:legal_name]).to eq(business.legal_name)
      expect(hash[:trading_name]).to eq(business.trading_name)
    end
  end
end
