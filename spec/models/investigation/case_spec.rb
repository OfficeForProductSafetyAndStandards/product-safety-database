require "rails_helper"

RSpec.describe Investigation::Case do
  subject(:case_object) { build(:case) }

  describe "#case_type" do
    it "returns 'notification'" do
      expect(case_object.case_type).to eq("notification")
    end
  end

  describe "#valid?" do
    subject(:case) { build(:case, date_received:).build_owner_collaborations_from(create(:user)) }

    context "with valid date_received" do
      let(:date_received) { 1.day.ago }

      it { is_expected.to be_valid }
    end

    context "with empty date_received" do
      let(:date_received) { nil }

      it { is_expected.to be_valid }
    end
  end
end
