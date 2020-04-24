module Investigations::TsInstigationsHelper
  def why_reporting_checkboxes(form, page_heading, errors)
    render "form_components/govuk_checkboxes",
           form: form,
           key: :why_reporting,
           fieldset: { legend: { html: page_heading_html(page_heading) }, classes: "js-mutually-exclusive" },
           hint: { text: "Select all that apply" },
           errorMessage: errors.any? ? { text: errors.full_messages_for(:base).to_sentence } : nil,
           items: [
             {
               key: "reported_reason_unsafe",
               text: "It’s unsafe (or suspected to be)",
               id: "base",
               value: true,
               conditional: { html: unsafe_details_html(form, hazard_types) },
               attributes: { class: "js-mutually-exclusive__item", data: { "mutually-exclusive-set-id": "reported-set" } }
             },
             {
               key: "reported_reason_non_compliant",
               text: "It’s non-compliant (or suspected to be)",
               value: true,
               conditional: { html: non_compliant_details_html(form) },
               attributes: { class: "js-mutually-exclusive__item", data: { "mutually-exclusive-set-id": "reported-set" } }
             },
             {
               key: "or",
               divider: "or"
             },
             {
               key: "reported_reason_safe_and_compliant",
               text: "It’s safe and compliant",
               hint: { text: "Help other market surveillance authorities avoid testing the same product again" },
               value: true,
               attributes: { class: "js-mutually-exclusive__item", data: { "mutually-exclusive-set-id": "safe-set" } }
             }
           ]
  end

  def page_heading_html(page_heading)
    render "investigations/ts_investigations/why_reporting_form_heading", page_heading: page_heading
  end

  def unsafe_details_html(form, hazard_types)
    render "investigations/ts_investigations/why_reporting_form_unsafe_details", form: form, hazard_types: hazard_types
  end

  def non_compliant_details_html(form)
    render "form_components/govuk_textarea",
           key: :non_compliant_reason,
           form: form,
           id: "non_compliant_reason",
           attributes: { maxlength: 10000 },
           label: { text: "Why is the product non-compliant?" },
           classes: "govuk-!-width-three-quarters"
  end
end
