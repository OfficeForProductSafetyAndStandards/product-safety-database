module Investigations
  module CorrectiveActionsHelper
    def corrective_action_summary_list_rows(corrective_action)
      business = corrective_action.business ? link_to(corrective_action.business.trading_name, business_path(corrective_action.business)) : "Not specified"
      rows = [
        { key: { text: "Date of action" },      value: { text: corrective_action.date_of_activity_string } },
        { key: { text: "Legislation" },         value: { text: corrective_action.legislation } },
        { key: { text: "Product" },             value: { html: link_to(corrective_action.product.name, product_path(corrective_action.product)) } },
        { key: { text: "Business" },            value: { html: business } },
      ]

      rows << { key: { text: "Type of action" },      value: { text: corrective_action.measure_type } } if corrective_action.measure_type.present?
      rows << { key: { text: "Duration of measure" }, value: { text: corrective_action.duration } }
      rows << { key: { text: "Scope" },               value: { text: corrective_action.geographic_scope } }
      rows << { key: { text: "Other details" },       value: { text: corrective_action.details } }      if corrective_action.details.present?

      rows
    end
  end
end
