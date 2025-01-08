require "rails_helper"

RSpec.describe Business do
  subject(:business) { build(:business, trading_name:) }

  let(:trading_name) { Faker::Restaurant.name }

  describe "#valid?" do
    context "with valid input" do
      it "returns true" do
        expect(business).to be_valid
      end
    end

    context "with blank trading_name" do
      let(:trading_name) { nil }

      it "returns false" do
        expect(business).not_to be_valid
      end
    end
  end
end
