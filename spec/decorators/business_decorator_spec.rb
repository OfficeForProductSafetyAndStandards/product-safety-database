require "rails_helper"

RSpec.describe BusinessDecorator, :with_stubbed_elasticsearch do
  subject(:decorated_business) { business.decorate }

  let(:business) { create(:business, locations: [location], contacts: [contact]) }
  let(:location) { build(:location, business: nil) }
  let(:contact) { build(:contact, business: nil) }

  describe "#to_csv" do
    # rubocop:disable RSpec/ExampleLength
    it "returns an Array of decorated attributes" do
      expect(decorated_business.to_csv).to eq([
        decorated_business.case_ids,
        decorated_business.company_number,
        decorated_business.created_at,
        decorated_business.id,
        decorated_business.legal_name,
        contact.email,
        contact.job_title,
        contact.name,
        contact.phone_number,
        location.address_line_1,
        location.address_line_2,
        location.city,
        location.country,
        location.county,
        location.phone_number,
        location.postal_code,
        decorated_business.trading_name,
        decorated_business.types,
        decorated_business.updated_at
      ])
    end
    # rubocop:enable RSpec/ExampleLength

    context "with no contacts" do
      let(:business) { create(:business, locations: [location]) }

      it "returns nil values for the contact attributes" do
        expect(decorated_business.to_csv.slice(5, 4)).to eq([nil, nil, nil, nil])
      end
    end

    context "with no locations" do
      let(:business) { create(:business, contacts: [contact]) }

      it "returns nil values for the location attributes" do
        expect(decorated_business.to_csv.slice(9, 7)).to eq([nil, nil, nil, nil, nil, nil, nil])
      end
    end
  end
end
