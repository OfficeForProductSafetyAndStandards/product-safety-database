RSpec.describe Collaboration::Access, :with_stubbed_mailer do
  describe ".changeable" do
    before do
      create(:allegation, edit_access_teams: [create(:team)], read_only_teams: [create(:team)])
    end

    it "returns only the records of subclasses where #changeable? is true (i.e. not Owner)" do
      expect(described_class.changeable.count).to eq(2)
    end
  end

  describe ".class_from_human_name" do
    it "returns the subclass with corresponding human_name" do
      expect(described_class.class_from_human_name(:edit)).to eq(Collaboration::Access::Edit)
    end
  end
end
