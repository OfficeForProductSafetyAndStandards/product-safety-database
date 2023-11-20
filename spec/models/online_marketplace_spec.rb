require "rails_helper"

RSpec.describe OnlineMarketplace do
  it "has a valid factory" do
    expect(build(:online_marketplace)).to be_valid
  end
end
