require "rails_helper"

RSpec.describe BusinessDecorator, :with_stubbed_elasticsearch do
  subject(:decorated_business) { business.decorate }

  let(:business) { create(:business) }

  describe "#to_csv" do
    # rubocop:disable RSpec/ExampleLength
    it "returns an Array of decorated attributes" do
      expect(decorated_business.to_csv).to eq([
        decorated_business.id,
        decorated_business.company_number,
        decorated_business.created_at,
        decorated_business.legal_name,
        decorated_business.trading_name,
        decorated_business.updated_at,
        decorated_business.types
      ])
    end
    # rubocop:enable RSpec/ExampleLength
  end
end
