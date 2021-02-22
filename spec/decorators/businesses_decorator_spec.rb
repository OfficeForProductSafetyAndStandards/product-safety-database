require "rails_helper"

RSpec.describe BusinessesDecorator, :with_stubbed_elasticsearch do
  subject(:decorated_businesses) { Business.all.decorate }

  let!(:business_1) { create(:business).decorate }
  let!(:business_2) { create(:business).decorate }

  describe "#to_csv" do
    it "returns a CSV string" do
      expect(decorated_businesses.to_csv).to eq("id,company_number,created_at,legal_name,trading_name,updated_at,types,case_ids\n#{business_1.id},#{business_1.company_number},#{business_1.created_at},#{business_1.legal_name},#{business_1.trading_name},#{business_1.updated_at},[],[]\n#{business_2.id},#{business_2.company_number},#{business_2.created_at},#{business_2.legal_name},#{business_2.trading_name},#{business_2.updated_at},[],[]\n")
    end
  end
end
