module Investigations
  module CorrectiveActionsHelper
    def corrective_action_summary_list_rows(corrective_action)
      rows = [
        { key: { text: "Action" },              value: { text: action_text_for(corrective_action) } },
        { key: { text: "Date of action" },      value: { text: corrective_action.date_of_activity } },
        { key: { text: "Legislation" },         value: { text: corrective_action.legislation } },
        { key: { text: "Recall information" },  value: { text: online_recall_information_for_text(corrective_action) } },
        { key: { text: "Product" },             value: { html: link_to(corrective_action.product.name, product_path(corrective_action.product)) } },
        { key: { text: "Business" },            value: { html: business_text_for(corrective_action) } },
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

    def online_recall_information_for_text(corrective_action)
      return corrective_action.online_recall_information if corrective_action.has_online_recall_information_yes?

      I18n.t(".#{corrective_action.object.has_online_recall_information}", scope: %i[investigations corrective_actions helper])
    end
  end
end
