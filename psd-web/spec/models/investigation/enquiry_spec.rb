require "rails_helper"

RSpec.describe Investigation::Enquiry do
  subject(:enquiry) { build(:enquiry, date_received: date_received, date_received_day: date_received_day, date_received_month: date_received_month, date_received_year: date_received_year, owner: owner) }

  let(:owner) { create(:user) }
  let(:date_received_day) { nil }
  let(:date_received_month) { nil }
  let(:date_received_year) { nil }

  describe "#valid?" do
    context "with valid date_received" do
      let(:date_received) { 1.day.ago }

      it "returns true" do
        expect(enquiry.valid?).to be true
      end
    end

    context "with empty date_received" do
      let(:date_received) { nil }

      it "returns true" do
        expect(enquiry.valid?).to be true
      end
    end

    context "with :about_enquiry option" do
      context "with valid date_received" do
        let(:date_received) { 1.day.ago }

        it "returns true" do
          expect(enquiry.valid?).to be true
        end
      end

      context "with empty date_received" do
        let(:date_received) { nil }

        it "returns false" do
          expect(enquiry.valid?(:about_enquiry)).to be false
        end

        context "with date components" do
          let(:date_received_day) { 1 }
          let(:date_received_month) { 1 }
          let(:date_received_year) { 1 }

          context "with date in the past" do
            it "returns true" do
              expect(enquiry.valid?(:about_enquiry)).to be true
            end
          end

          context "with date in the future" do
            let(:date_received_year) { 9999 }

            it "returns false" do
              expect(enquiry.valid?(:about_enquiry)).to be false
            end
          end

          context "with empty component" do
            let(:date_received_year) { nil }

            it "returns false" do
              expect(enquiry.valid?(:about_enquiry)).to be false
            end
          end

          context "with non-numeric components" do
            let(:date_received_day) { "day" }
            let(:date_received_month) { "month" }
            let(:date_received_year) { "year" }

            it "returns false" do
              expect(enquiry.valid?(:about_enquiry)).to be false
            end
          end
        end
      end

      context "with date_received in the future" do
        let(:date_received) { Time.zone.today + 1.year }

        it "returns false" do
          expect(enquiry.valid?(:about_enquiry)).to be false
        end
      end
    end
  end
end
