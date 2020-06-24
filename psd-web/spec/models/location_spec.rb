require "rails_helper"

RSpec.describe Location do
  subject(:location) { described_class.new(county: county, country: country) }

  let(:county) { "L" }
  let(:country) { "C" }

  describe "#short" do
    context "with a county" do
      it "returns a string containing county and country" do
        expect(location.short).to eq("L, C")
      end
    end

    context "without a county" do
      let(:county) { nil }

      it "returns a string containing only country" do
        expect(location.short).to eq("C")
      end
    end
  end
end
