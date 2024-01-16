RSpec.describe Location do
  subject(:location) { described_class.new(county:, country:) }

  let(:county) { "L" }
  let(:country) { "C" }

  describe "factory" do
    it "is valid" do
      expect(build(:location)).to be_valid
    end
  end

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
