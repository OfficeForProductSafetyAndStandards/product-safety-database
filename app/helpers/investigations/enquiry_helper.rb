module Investigations::EnquiryHelper
  def date_received(form)
    govukDateInput(
      form:,
      key: :date_received,
      fieldset: { legend: { text: "When was it received?", classes: "govuk-fieldset__legend--m" } }
    )
  end

  def received_type(form)
    [{ text: "Email",
       value: "email" },
     { text: "Phone",
       value: "phone" },
     { text: "Other",
       value: "other",
       conditional: { html: other_type(form) } }]
  end

  def other_type(form)
    govukInput(
      key: :other_received_type,
      value: params.dig(:enquiry, :other_received_type),
      form:,
      label: { text: "Other received type", classes: "govuk-visually-hidden" }
    )
  end
end
