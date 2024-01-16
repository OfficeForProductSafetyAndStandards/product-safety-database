RSpec.describe Collaboration::Access::Edit do
  describe ".changeable?" do
    it "returns true" do
      expect(described_class).to be_changeable
    end
  end
end
