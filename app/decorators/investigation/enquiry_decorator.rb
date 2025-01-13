class Investigation < ApplicationRecord
  require_dependency "investigation"
  class EnquiryDecorator < InvestigationDecorator
    def source_details_summary_list(view_protected_details: false)
      contact_details = view_protected_details ? contact_details_list : h.tag.p("")
      contact_details << h.tag.p(I18n.t("case.protected_details", data_type: "#{object.case_type} contact details"), class: "govuk-body-s govuk-!-margin-bottom-1 opss-secondary-text opss-text-align-right")

      rows = [
        { key: { text: "Received date" }, value: { text: date_received&.to_formatted_s(:govuk) } },
        { key: { text: "Received by" }, value: { text: received_type&.upcase_first } },
        { key: { text: "Source type" }, value: { text: complainant&.complainant_type } },
        { key: { text: "Contact details" }, value: { text: contact_details } }
      ]

      h.govuk_summary_list(rows:, borders: false, classes: "opss-summary-list-mixed opss-summary-list-mixed--narrow-dt")
    end
  end
end
