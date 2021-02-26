module Investigations
  module AccidentOrIncidentsHelper
    def accident_or_incident_summary_list_rows(accident_or_incident)
      rows = [
        { key: { text: "Date of accident" }, value: { text: accident_or_incident.date_of_activity } },
        { key: { text: "Product" },          value: { html: link_to(accident_or_incident.product.name, product_path(accident_or_incident.product)) } },
        { key: { text: "Severity" },         value: { text: accident_or_incident.severity } },
        { key: { text: "Product usage" },    value: { html: accident_or_incident.usage } }
      ]

      unless accident_or_incident.additional_info.blank?
        rows << { key: { text: "Additional Information" },  value: { html: accident_or_incident.additional_info } }
      end

      rows
    end
  end
end
