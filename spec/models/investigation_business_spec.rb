RSpec.describe InvestigationBusiness do
  it "has a valid factory" do
    expect(build(:investigation_business)).to be_valid
  end

  context "without a online_marketplace" do
    it { expect(build(:investigation_business, online_marketplace: nil)).to be_valid }
  end

  context "with a online_marketplace" do
    it { expect(build(:investigation_business, online_marketplace: create(:online_marketplace))).to be_valid }
  end

  context "without a business" do
    it { expect(build(:investigation_business, business: nil)).not_to be_valid }
  end

  context "without an investigation" do
    it { expect(build(:investigation_business, investigation: nil)).not_to be_valid }
  end
end
