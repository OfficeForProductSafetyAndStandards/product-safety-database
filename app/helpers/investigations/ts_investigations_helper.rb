module Investigations::TsInvestigationsHelper
  def edit_why_reporting_checkboxes(form, page_heading, errors, disabled: true, classes: nil, attribute: :base)
    base_errors = errors.full_messages_for(attribute)
    attributes[:disabled] = "disabled" if disabled

    govukCheckboxes(
      form:,
      key: :why_reporting,
      fieldset: { legend: { html: edit_page_heading_html(page_heading), classes: "govuk-fieldset__legend--l" } },
      hint: { text: "Select one or both descriptions." },
      errorMessage: base_errors.any? ? { text: base_errors.to_sentence } : nil,
      classes:,
      items: [
        { key: "reported_reason_unsafe",
          text: "The product is unsafe",
          id: attribute.to_s,
          value: true,
          conditional: { html: edit_unsafe_details_html(form, hazard_types) },
          disable_ghost: true,
          attributes: },
        { key: "reported_reason_non_compliant",
          text: "The product is non-compliant",
          value: true,
          conditional: { html: non_compliant_details_html(form) },
          disable_ghost: true,
          attributes: }
      ]
    )
  end

private

  def edit_page_heading_html(page_heading)
    render "investigations/why_reporting_form_heading", page_heading:
  end

  def edit_unsafe_details_html(form, hazard_types)
    render "investigations/why_reporting_form_unsafe_details", form:, hazard_types:
  end

  def non_compliant_details_html(form)
    govukTextarea(
      key: :non_compliant_reason,
      form:,
      id: "non_compliant_reason",
      attributes: { maxlength: 10_000 },
      label: { text: "Why is the product non-compliant?" },
      classes: "govuk-!-width-three-quarters"
    )
  end
end
