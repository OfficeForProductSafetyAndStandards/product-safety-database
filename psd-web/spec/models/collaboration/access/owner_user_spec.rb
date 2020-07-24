require "rails_helper"

RSpec.describe Collaboration::Access::OwnerUser do
  describe ".can_be_changed?" do
    it "returns false" do
      expect(described_class.can_be_changed?).to be false
    end
  end
end
