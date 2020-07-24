require "rails_helper"

RSpec.describe Collaboration::Access::Edit do
  describe ".can_be_changed?" do
    it "returns true" do
      expect(described_class.can_be_changed?).to be true
    end
  end
end
