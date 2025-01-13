require "rails_helper"

RSpec.describe Investigation::EnquiryDecorator, :with_stubbed_mailer do
  include ActionView::Helpers::DateHelper

  subject(:decorated_investigation) { investigation.decorate }

  let(:user)          { build_stubbed(:user) }
  let(:investigation) { create(:enquiry) }

  before do
    create(:complainant, investigation:)
  end

  describe "#source_details_summary_list" do
    let(:source_details_summary_list) { decorated_investigation.source_details_summary_list(view_protected_details: false) }

    context "when date_received and received_type are present" do
      it "displays the Received date" do
        expect(source_details_summary_list).to summarise("Received date", text: investigation.date_received.to_formatted_s(:govuk))
      end

      it "displays the Received by" do
        expect(source_details_summary_list).to summarise("Received by", text: investigation.received_type.upcase_first)
      end

      it "displays the Source type" do
        expect(source_details_summary_list).to summarise("Source type", text: investigation.complainant.complainant_type)
      end
    end

    context "when date_received is nil" do
      let(:investigation) { create(:enquiry, date_received: nil) }

      it "displays the Received date with empty value" do
        expect(source_details_summary_list).to summarise("Received date", text: nil)
      end

      it "displays other fields" do
        expect(source_details_summary_list).to summarise("Received by", text: investigation.received_type.upcase_first)
        expect(source_details_summary_list).to summarise("Source type", text: investigation.complainant.complainant_type)
      end
    end

    context "when received_type is nil" do
      let(:investigation) { create(:enquiry, received_type: nil) }

      it "displays the Received by with empty value" do
        expect(source_details_summary_list).to summarise("Received by", text: nil)
      end

      it "displays other fields" do
        expect(source_details_summary_list).to summarise("Received date", text: investigation.date_received.to_formatted_s(:govuk))
        expect(source_details_summary_list).to summarise("Source type", text: investigation.complainant.complainant_type)
      end
    end

    context "when both date_received and received_type are nil" do
      let(:investigation) { create(:enquiry, date_received: nil, received_type: nil) }

      it "displays the Received date and Received by with empty values" do
        expect(source_details_summary_list).to summarise("Received date", text: nil)
        expect(source_details_summary_list).to summarise("Received by", text: nil)
      end

      it "displays the Source type" do
        expect(source_details_summary_list).to summarise("Source type", text: investigation.complainant.complainant_type)
      end
    end
  end

  describe "#title" do
    context "with a user_title" do
      let(:user_title) { "user title" }
      let(:investigation) { create(:enquiry, user_title:, complainant_reference: nil) }

      it { expect(decorated_investigation.title).to eq(user_title) }
    end

    context "without a user_title but with a complainant_reference" do
      let(:complainant_reference) { "complainant reference" }
      let(:investigation) { create(:enquiry, user_title: nil, complainant_reference:) }

      it { expect(decorated_investigation.title).to eq(complainant_reference) }
    end

    context "without a user_title or a complainant_reference" do
      let(:investigation) { create(:enquiry, user_title: nil, complainant_reference: nil) }

      it "uses the pretty_id" do
        expect(decorated_investigation.title).to eq(investigation.pretty_id)
      end
    end
  end
end
