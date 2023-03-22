require "rails_helper"

RSpec.describe Investigations::CorrectiveActionsHelper, :with_stubbed_opensearch, :with_stubbed_mailer do
  describe "#corrective_action_summary_list_rows" do
    let(:business)                           { create(:business) }
    let(:corrective_action)                  { create(:corrective_action, date_decided: 2.weeks.ago, has_online_recall_information:, business:).decorate }
    let(:expected_online_recall_information) { corrective_action.online_recall_information }
    let(:has_online_recall_information)      { CorrectiveAction.has_online_recall_informations["has_online_recall_information_yes"] }
    let(:expected_rows) do
      [
        { key: { text: "Event date" }, value: { text: corrective_action.date_of_activity } },
        { key: { text: "Legislation" }, value: { text: corrective_action.legislation } },
        { key: { text: "Recall information" }, value: { html: match(expected_online_recall_information) } },
        { key: { text: "Product" }, value: { text: "#{corrective_action.investigation_product.name} (#{corrective_action.investigation_product.psd_ref})" } },
        { key: { text: "Business" }, value: { html: helper.link_to(corrective_action.business.trading_name, helper.business_path(corrective_action.business)) } },
        { key: { text: "Type of action" }, value: { text: corrective_action.measure_type.upcase_first } },
        { key: { text: "Duration of measure" }, value: { text: corrective_action.duration.upcase_first } },
        { key: { text: "Geographic scopes" }, value: { text: corrective_action.geographic_scopes } }
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

    context "with online recall information" do
      context "when online recall information is not a url" do
        before { corrective_action.update!(online_recall_information: "something other than a url") }

        it "displays online recall info" do
          expect(helper.corrective_action_summary_list_rows(corrective_action)).to include(key: { text: "Recall information" }, value: { html: expected_online_recall_information.to_s })
        end

        it "does not link to the recall information" do
          expect(helper.corrective_action_summary_list_rows(corrective_action)).not_to include(key: { text: "Recall information" }, value: { html: /href/ })
        end
      end

      context "when online_recall_information is a url" do
        it "displays online recall info" do
          expect(helper.corrective_action_summary_list_rows(corrective_action)).to include(key: { text: "Recall information" }, value: { html: /"#{expected_online_recall_information}"/ })
        end

        it "links to the recall information" do
          expect(helper.corrective_action_summary_list_rows(corrective_action)).to include(key: { text: "Recall information" }, value: { html: /href/ })
        end
      end
    end

    context "with no online recall information" do
      let(:has_online_recall_information) { CorrectiveAction.has_online_recall_informations["has_online_recall_information_no"] }
      let(:expected_online_recall_information) { "Not published online" }

      it "show the no recall information published online" do
        expect(helper.corrective_action_summary_list_rows(corrective_action)).to include(key: { text: "Recall information" }, value: { html: expected_online_recall_information })
      end
    end

    context "when not provided" do
      let(:has_online_recall_information) { CorrectiveAction.has_online_recall_informations["has_online_recall_information_not_relevant"] }
      let(:expected_online_recall_information) { "Not relevant" }

      it "shows not relevant" do
        expect(helper.corrective_action_summary_list_rows(corrective_action)).to include(key: { text: "Recall information" }, value: { html: expected_online_recall_information })
      end
    end

    context "with no online recall information was previously set" do
      let(:has_online_recall_information) { nil }

      it "does not show the recall information published online" do
        expect(helper.corrective_action_summary_list_rows(corrective_action)).to include(key: { text: "Recall information" }, value: { html: "Not provided" })
      end
    end
  end
end
