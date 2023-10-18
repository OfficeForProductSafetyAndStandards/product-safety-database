require "rails_helper"

RSpec.describe OnlineMarketplace do
  it "has a valid factory" do
    expect(build(:online_marketplace)).to be_valid
  end

  describe "business association" do
    it { is_expected.to belong_to(:business).optional }
  end

end
