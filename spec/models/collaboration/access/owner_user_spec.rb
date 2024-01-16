RSpec.describe Collaboration::Access::OwnerUser do
  describe ".changeable?" do
    it "returns false" do
      expect(described_class).not_to be_changeable
    end
  end
end
