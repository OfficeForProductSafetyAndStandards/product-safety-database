module Investigations
  module AccidentOrIncidentsHelper
    def accident_or_incident_summary_list_rows(accident_or_incident)
      rows = [
        { key: { text: "Date of #{accident_or_incident.type.downcase}" }, value: { text: accident_or_incident.date_of_activity } },
        { key: { text: "Product" }, value: { text: "#{accident_or_incident.investigation_product.name} (#{accident_or_incident.investigation_product.psd_ref})" } },
        { key: { text: "Severity" }, value: { text: accident_or_incident.severity } },
        { key: { text: "Product usage" }, value: { text: accident_or_incident.usage } }
      ]

      if accident_or_incident.additional_info.present?
        rows << { key: { text: "Additional Information" }, value: { text: accident_or_incident.additional_info } }
      end

      rows
    end
  end
end
