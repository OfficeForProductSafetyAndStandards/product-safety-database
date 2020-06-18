require "rails_helper"

RSpec.describe Investigations::CorrectiveActionsHelper, :with_stubbed_elasticsearch, :with_stubbed_mailer do
  describe "#corrective_action_summary_list_rows" do
    let(:business)          { create(:business) }
    let(:corrective_action) { create(:corrective_action, date_decided: 2.weeks.ago, business: business).decorate }

    let(:expected_rows) do
      [
        { key: { text: "Date of action" }, value: { text: corrective_action.date_of_activity } },
        { key: { text: "Legislation" }, value: { text: corrective_action.legislation } },
        { key: { text: "Product" }, value: { html: helper.link_to(corrective_action.product.name, helper.product_path(corrective_action.product)) } },
        { key: { text: "Business" }, value: { html: helper.link_to(corrective_action.business.trading_name, helper.business_path(corrective_action.business)) } },
        { key: { text: "Type of action" }, value: { text: corrective_action.measure_type.upcase_first } },
        { key: { text: "Duration of measure" }, value: { text: corrective_action.duration.upcase_first } },
        { key: { text: "Scope" }, value: { text: corrective_action.geographic_scope } }
      ]
    end

    context "when all details are presents" do
      it "displays every rows" do
        expect(helper.corrective_action_summary_list_rows(corrective_action)).to include(*expected_rows)
      end
    end

    context "when no business is present" do
      let(:business) { nil }

      it "does not link to the business" do
        expect(helper.corrective_action_summary_list_rows(corrective_action)).to include(key: { text: "Business" }, value: { html: "Not specified" })
      end
    end

    context "when no measure_type" do
      before { corrective_action.measure_type = nil }

      it "does not show the type of action" do
        expect(helper.corrective_action_summary_list_rows(corrective_action)).not_to include(key: { text: "Type of action" }, value: { text: nil })
      end
    end

    context "when no details" do
      before { corrective_action.details = nil }

      it "does not show the type of action" do
        expect(helper.corrective_action_summary_list_rows(corrective_action)).not_to include(key: { text: "Other details" }, value: { text: nil })
      end
    end
  end
end
