module Investigations
  module CorrectiveActionsHelper
    def corrective_action_summary_list_rows(corrective_action)
      recall_information = online_recall_information_text_for(corrective_action.online_recall_information, has_online_recall_information: corrective_action.has_online_recall_information)
      recall_information = link_to(recall_information) if recall_information.starts_with?("http")
      rows = [
        { key: { text: "Action" },                    value: { text: action_text_for(corrective_action) } },
        { key: { text: "Date of action" },            value: { text: corrective_action.date_of_activity } },
        { key: { text: "Legislation" },               value: { text: corrective_action.legislation } },
        { key: { text: "Product" },                   value: { html: link_to(corrective_action.product.name, product_path(corrective_action.product)) } },
        { key: { text: "Business" },                  value: { html: business_text_for(corrective_action) } },
        { key: { text: "Recall information" },        value: { html: recall_information } }
      ]
      rows << { key: { text: "Type of action" },      value: { text: corrective_action.measure_type } } if corrective_action.measure_type.present?
      rows << { key: { text: "Duration of measure" }, value: { text: corrective_action.duration } }
      rows << { key: { text: "Scope" },               value: { text: corrective_action.geographic_scope } }
      rows << { key: { text: "Other details" },       value: { text: corrective_action.details } }      if corrective_action.details.present?

      rows
    end

  private

    def action_text_for(corrective_action)
      corrective_action.other? ? corrective_action.other_action : corrective_action.action_label
    end

    def business_text_for(corrective_action)
      corrective_action.business ? link_to(corrective_action.business.trading_name, business_path(corrective_action.business)) : I18n.t(".not_specified", scope: %i[investigations corrective_actions helper])
    end

    def online_recall_information_text_for(online_recall_information, has_online_recall_information:)
      return link_to(online_recall_information, online_recall_information, rel: "noopener", target: "_blank") if has_online_recall_information&.inquiry&.has_online_recall_information_yes?
      return I18n.t(".has_online_recall_information_not_provided", scope: %i[investigations corrective_actions helper has_online_recall_information]) if has_online_recall_information.nil?

      I18n.t(".#{has_online_recall_information}", scope: %i[investigations corrective_actions helper has_online_recall_information])
    end
  end
end
