require "rails_helper"

RSpec.describe Investigation::Enquiry do
  subject(:enquiry) { build(:enquiry, date_received: date_received).build_owner_collaborations_from(create(:user)) }

  describe "#valid?" do
    context "with valid date_received" do
      let(:date_received) { 1.day.ago }

      it { is_expected.to be_valid }
    end

    context "with empty date_received" do
      let(:date_received) { nil }

      it { is_expected.to be_valid }
    end

    context "with :about_enquiry option" do
      context "with valid date_received" do
        let(:date_received) { 1.day.ago }

        it { is_expected.to be_valid }
      end

      context "with empty date_received" do
        let(:date_received) { nil }

        it { is_expected.not_to be_valid :about_enquiry }
      end

      context "with date_received in the future" do
        let(:date_received) { Time.zone.today + 1.year }

        it { is_expected.not_to be_valid :about_enquiry }
      end
    end
  end
end
