RSpec.describe UcrNumber do
  describe "validations" do
    subject { build(:ucr_number) }

    it { is_expected.to be_valid }
    it { is_expected.to validate_presence_of(:number) }
    it { is_expected.to belong_to(:investigation_product) }
  end
end
