require "rails_helper"

RSpec.describe Investigation::EnquiryDecorator, :with_stubbed_elasticsearch, :with_stubbed_mailer do
  include ActionView::Helpers::DateHelper

  subject(:decorated_investigation) { investigation.decorate }

  let(:user)                      { create(:user) }
  let(:investigation)             { create(:enquiry, date_received_year: 2020, date_received_month: 1, date_received_day: 1, source: build(:user_source, sourceable: user)) }
  let(:viewing_user_organisation) { user.organisation }
  let(:viewing_user_team)         { user.team }
  let(:viewing_user)              { create(:user, organisation: viewing_user_organisation, teams: [viewing_user_team]) }
  let!(:complainant)              { create(:complainant, complainant_type: "Consumer", investigation: investigation).decorate }

  describe "#source_details_summary_list" do
    let(:source_details_summary_list) { decorated_investigation.source_details_summary_list(viewing_user) }

    it "displays the Received date" do
      expect(source_details_summary_list).to summarise("Received date", text: investigation.date_received.to_s(:govuk))
    end

    it "displays the Received by" do
      expect(source_details_summary_list).to summarise("Received by", text: investigation.received_type.upcase_first)
    end
  end
end
