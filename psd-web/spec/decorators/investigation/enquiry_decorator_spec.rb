require "rails_helper"

RSpec.describe Investigation::EnquiryDecorator, :with_stubbed_elasticsearch, :with_stubbed_mailer do
  include ActionView::Helpers::DateHelper

  subject(:decorated_investigation) { investigation.decorate }

  let(:user)          { build_stubbed(:user) }
  let(:investigation) { create(:enquiry, date_received_year: 2020, date_received_month: 1, date_received_day: 1) }

  before do
    create(:complainant, investigation: investigation)
  end

  describe "#source_details_summary_list" do
    let(:source_details_summary_list) { decorated_investigation.source_details_summary_list(user) }

    it "displays the Received date" do
      expect(source_details_summary_list).to summarise("Received date", text: investigation.date_received.to_s(:govuk))
    end

    it "displays the Received by" do
      expect(source_details_summary_list).to summarise("Received by", text: investigation.received_type.upcase_first)
    end
  end
end
