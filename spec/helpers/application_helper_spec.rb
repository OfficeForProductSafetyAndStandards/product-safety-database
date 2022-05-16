require "rails_helper"

describe ApplicationHelper do
  describe "#error_summary" do
    let(:view_class) do
      Class.new do
        include ApplicationHelper
        include GovukDesignSystem::ErrorSummaryHelper
      end
    end

    let(:view) { view_class.new }
    let(:base) { User.new }
    let(:errors) do
      [
        ActiveModel::Error.new(base, :name, :blank),
        ActiveModel::Error.new(base, :email, :blank),
        ActiveModel::Error.new(base, :mobile_number, :invalid),
      ]
    end

    before { allow(view).to receive(:govukErrorSummary) }

    def expect_error_summary_for(formatted_errors)
      expect(view).to have_received(:govukErrorSummary).with(
        titleText: "There is a problem",
        errorList: formatted_errors,
      )
    end

    context "when no attributes order is given" do
      let(:order) { [] }

      it "calls for the error summary with a formatted unordered list of errors" do
        view.error_summary(errors, order)
        expect_error_summary_for([{ text: "Enter your full name", href: "#name" },
                                  { text: "Email cannot be blank", href: "#email" },
                                  { text: "Enter your mobile number in the correct format, like 07700 900 982", href: "#mobile_number" }])
      end
    end

    context "when providing a list with attributes order" do
      context "with all the attributes defined in the order" do
        let(:order) { %i[mobile_number email name] }

        it "generates the error summary with an ordered and formatted list of errors" do
          view.error_summary(errors, order)
          expect_error_summary_for([{ text: "Enter your mobile number in the correct format, like 07700 900 982", href: "#mobile_number" },
                                    { text: "Email cannot be blank", href: "#email" },
                                    { text: "Enter your full name", href: "#name" }])
        end
      end

      context "when some attribute is missing in the order" do
        let(:order) { %i[mobile_number name] }

        it "adds the attribute errors after the ordered ones" do
          view.error_summary(errors, order)
          expect_error_summary_for([{ text: "Enter your mobile number in the correct format, like 07700 900 982", href: "#mobile_number" },
                                    { text: "Enter your full name", href: "#name" },
                                    { text: "Email cannot be blank", href: "#email" }])
        end
      end

      context "when the order includes attributes without errors" do
        let(:order) { %i[bar name foo mobile_number email] }

        it "ignores them and respects the order for the attributes with errors" do
          view.error_summary(errors, order)
          expect_error_summary_for([{ text: "Enter your full name", href: "#name" },
                                    { text: "Enter your mobile number in the correct format, like 07700 900 982", href: "#mobile_number" },
                                    { text: "Email cannot be blank", href: "#email" }])
        end
      end
    end
  end

  describe "#date_or_recent_time_ago" do
    it "returns time ago in words within the last 24 hours" do
      expect(helper.date_or_recent_time_ago(10.minutes.ago)).to eq("10 minutes ago")
    end

    it "returns the date in GovUK format outside of the last 24 hours" do
      travel_to Time.zone.local(2000, 1, 1, 0, 0, 0) do
        expect(helper.date_or_recent_time_ago(25.hours.ago)).to eq("30 December 1999")
      end
    end
  end
end
