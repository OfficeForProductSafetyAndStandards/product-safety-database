require "rails_helper"

RSpec.describe Investigation::Notification do
  subject(:notification) { build(:notification) }

  describe "#case_type" do
    it "returns 'notification'" do
      expect(notification.case_type).to eq("notification")
    end
  end

  describe "#valid?" do
    subject(:notification) { build(:notification, date_received:).build_owner_collaborations_from(create(:user)) }

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
