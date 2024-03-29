require "rails_helper"

RSpec.describe InvestigationDecorator, :with_stubbed_mailer do
  include ActionView::Helpers::DateHelper
  include ActionView::Helpers::TextHelper
  subject(:decorated_notification) { notification.decorate }

  let(:organisation)  { create :organisation }
  let(:user)          { create(:user, organisation:).decorate }
  let(:team)          { create(:team) }
  let(:creator)       { create(:user, :opss_user, organisation:, team:) }
  let(:products)      { [] }
  let(:risk_level)    { :serious }
  let(:coronavirus_related) { false }
  let(:notification) do
    create(:allegation,
           :reported_unsafe_and_non_compliant,
           products:,
           coronavirus_related:,
           creator:,
           risk_level:)
  end

  before do
    ChangeNotificationOwner.call!(notification:, user: creator, owner: user)
    create(:complainant, investigation: notification)
  end

  describe "#risk_level_description" do
    let(:risk_level_description) { decorated_notification.risk_level_description }

    context "when the risk level is set" do
      let(:notification) { create(:allegation, risk_level: :high) }

      it "displays the risk level text corresponding to the risk level" do
        expect(risk_level_description).to eq "High risk"
      end
    end

    context "when the risk level is set to other" do
      let(:notification) { create(:allegation, risk_level: "other", custom_risk_level: "Custom risk") }

      it "displays the custom risk level" do
        expect(risk_level_description).to eq "Custom risk"
      end
    end

    context "when the risk level and the custom risk level are not set" do
      let(:notification) { create(:allegation, risk_level: nil, custom_risk_level: nil) }

      it "displays 'Not set'" do
        expect(risk_level_description).to eq "Not set"
      end
    end
  end

  describe "#pretty_description" do
    it {
      expect(decorated_notification.pretty_description)
        .to eq("Notification: #{notification.pretty_id}")
    }
  end

  describe "#source_details_summary_list" do
    let(:view_protected_details) { true }
    let(:source_details_summary_list) { decorated_notification.source_details_summary_list(view_protected_details:) }

    it "does not display the Received date" do
      expect(source_details_summary_list).not_to summarise("Received date", text: notification.date_received.to_formatted_s(:govuk))
    end

    it "does not display the Received by" do
      expect(source_details_summary_list).not_to summarise("Received by", text: notification.received_type.upcase_first)
    end

    it "displays the Source type" do
      expect(source_details_summary_list).to summarise("Source type", text: notification.complainant.complainant_type)
    end

    context "when view_protected_details is true" do
      let(:view_protected_details) { true }

      it "displays the complainant details", :aggregate_failures do
        expect_to_display_protect_details_message
        expect(source_details_summary_list).to summarise("Contact details", text: /#{Regexp.escape(notification.complainant.name)}/)
        expect(source_details_summary_list).to summarise("Contact details", text: /#{Regexp.escape(notification.complainant.phone_number)}/)
        expect(source_details_summary_list).to summarise("Contact details", text: /#{Regexp.escape(notification.complainant.email_address)}/)
        expect(source_details_summary_list).to summarise("Contact details", text: /#{Regexp.escape(notification.complainant.other_details)}/)
      end
    end

    context "when view_protected_details is false" do
      let(:view_protected_details) { false }

      it "does not display the Complainant details", :aggregate_failures do
        expect_to_display_protect_details_message
        expect(source_details_summary_list).not_to summarise("Contact details", text: /#{Regexp.escape(notification.complainant.name)}/)
        expect(source_details_summary_list).not_to summarise("Contact details", text: /#{Regexp.escape(notification.complainant.phone_number)}/)
        expect(source_details_summary_list).not_to summarise("Contact details", text: /#{Regexp.escape(notification.complainant.email_address)}/)
        expect(source_details_summary_list).not_to summarise("Contact details", text: /#{Regexp.escape(notification.complainant.other_details)}/)
      end
    end

    def expect_to_display_protect_details_message
      expect(source_details_summary_list).to summarise("Contact details", text: /Only teams added to the notification can view allegation contact details/)
    end
  end

  describe "#description" do
    include_examples "a formated text", :notification, :description
    include_examples "with a blank description", :notification, :decorated_notification
  end

  describe "#owner_display_name_for" do
    let(:viewer) { build(:user) }

    it "displays the owner name" do
      expect(decorated_notification.owner_display_name_for(viewer:))
        .to eq(user.owner_short_name(viewer:))
    end
  end

  describe "#generic_attachment_partial" do
    let(:partial) { decorated_notification.generic_attachment_partial(viewing_user) }

    context "when the viewer has accees to view the restricted details" do
      let(:viewing_user) { notification.owner }

      it { expect(partial).to eq("documents/generic_document_card") }
    end

    context "when the viewer does not has accees to view the restricted details" do
      let(:viewing_user) { create(:user) }

      it { expect(partial).to eq("documents/restricted_generic_document_card") }
    end
  end

  describe "#title" do
    context "with a user_title" do
      let(:user_title) { "user title" }
      let(:notification) { create(:notification, user_title:, complainant_reference: nil) }

      it { expect(decorated_notification.title).to eq(user_title) }
    end

    context "without a user_title but with a complainant_reference" do
      let(:complainant_reference) { "complainant reference" }
      let(:notification) { create(:notification, user_title: nil, complainant_reference:) }

      it { expect(decorated_notification.title).to eq(complainant_reference) }
    end

    context "without a user_title or a complainant_reference" do
      let(:notification) { create(:notification, user_title: nil, complainant_reference: nil) }

      it "uses the pretty_id" do
        expect(decorated_notification.title).to eq(notification.pretty_id)
      end
    end
  end

  describe "#case_title_key" do
    let(:viewing_user) { create(:user) }
    let(:case_title_key) { decorated_notification.case_title_key(viewing_user) }
    let(:user_title)     { "user title" }

    context "with unrestricted case" do
      let(:notification) { create(:allegation, user_title:) }

      it { expect(case_title_key).to include(user_title) }
    end

    context "with restricted case" do
      let(:notification) { create(:allegation, user_title:, is_private: true) }

      it { expect(case_title_key).to eq("Notification restricted") }
    end

    context "with restricted case as a super user" do
      let(:notification) { create(:allegation, user_title:, is_private: true) }
      let(:viewing_user) { create(:user, :super_user) }

      it { expect(case_title_key).to include("user title") }
    end
  end

  describe "#case_summary_values" do
    let(:case_summary_values) { decorated_notification.case_summary_values }
    let(:text_values) { case_summary_values.pluck(:text).compact }
    let(:html_value) { case_summary_values.pluck(:text).compact.join }

    context "with unrestricted case" do
      let(:notification) { create(:allegation, is_closed: true) }

      it { expect(text_values).to include(notification.pretty_id) }
      it { expect(text_values).to include(notification.owner_team.name) }
      it { expect(html_value).to include("Closed") }
    end

    context "with restricted case" do
      let(:notification) { create(:allegation, is_private: true, is_closed: false) }

      it { expect(text_values).not_to include(notification.pretty_id) }
      it { expect(text_values).not_to include(notification.owner_team.name) }
      it { expect(html_value).to include("Open") }
    end
  end
end
