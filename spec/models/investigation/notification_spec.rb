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

  describe "#valid_api_dataset?" do
    context "with a valid API dataset" do
      subject(:notification) { build(:notification) }

      it { is_expected.to be_valid_api_dataset }
    end

    context "with an invalid API dataset" do
      subject(:notification) { build(:notification, user_title: nil) }

      it { is_expected.not_to be_valid_api_dataset }
    end
  end
end
