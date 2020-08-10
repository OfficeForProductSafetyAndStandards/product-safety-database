require "rails_helper"

RSpec.describe Investigation::Enquiry do
  subject(:enquiry) { build(:enquiry, date_received: date_received, date_received_day: date_received_day, date_received_month: date_received_month, date_received_year: date_received_year).build_owner_collaborations_from(create(:user)) }

  let(:date_received_day) { nil }
  let(:date_received_month) { nil }
  let(:date_received_year) { nil }

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

        context "with date components" do
          let(:date_received_day) { 1 }
          let(:date_received_month) { 1 }
          let(:date_received_year) { 1 }

          context "with date in the past" do
            it { is_expected.to be_valid :about_enquiry }
          end

          context "with date in the future" do
            let(:date_received_year) { 9999 }

            it { is_expected.not_to be_valid :about_enquiry }
          end

          context "with empty component" do
            let(:date_received_year) { nil }

            it { is_expected.not_to be_valid :about_enquiry }
          end

          context "with non-numeric components" do
            let(:date_received_day) { "day" }
            let(:date_received_month) { "month" }
            let(:date_received_year) { "year" }

            it { is_expected.not_to be_valid :about_enquiry }
          end
        end
      end

      context "with date_received in the future" do
        let(:date_received) { Time.zone.today + 1.year }

        it { is_expected.not_to be_valid :about_enquiry }
      end
    end
  end
end
