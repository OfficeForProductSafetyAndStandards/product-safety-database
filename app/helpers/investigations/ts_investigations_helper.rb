module Investigations::TsInvestigationsHelper
  def why_reporting_checkboxes(form, page_heading, errors)
    base_errors = errors.full_messages_for(:base)
    govukCheckboxes(
      form:,
      key: :why_reporting,
      fieldset: { legend: { html: page_heading_html(page_heading) }, classes: "js-mutually-exclusive" },
      hint: { text: "Select all that apply" },
      errorMessage: base_errors.any? ? { text: base_errors.to_sentence } : nil,
      items: [
        reported_unsafe_checkbox(form, hazard_types),
        reported_non_compliant_checkbox(form),
        { key: "or", divider: "or" },
        reported_safe_and_compliant_checkbox
      ]
    )
  end

  def edit_why_reporting_checkboxes(form, page_heading, errors, disabled: true, classes: nil, attribute: :base)
    base_errors = errors.full_messages_for(attribute)
    attributes = { class: "js-mutually-exclusive__item", data: { "mutually-exclusive-set-id": "reported-set" } }
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

  def page_heading_html(page_heading)
    render "investigations/ts_investigations/why_reporting_form_heading", page_heading:
  end

  def edit_page_heading_html(page_heading)
    render "investigations/why_reporting_form_heading", page_heading:
  end

  def unsafe_details_html(form, hazard_types)
    render "investigations/ts_investigations/why_reporting_form_unsafe_details", form:, hazard_types:
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

  def reported_unsafe_checkbox(form, hazard_types)
    {
      key: "reported_reason_unsafe",
      text: "It’s unsafe (or suspected to be)",
      id: "base",
      value: true,
      disable_ghost: true,
      conditional: { html: unsafe_details_html(form, hazard_types) },
      attributes: { class: "js-mutually-exclusive__item", data: { "mutually-exclusive-set-id": "reported-set" } }
    }
  end

  def reported_non_compliant_checkbox(form)
    {
      key: "reported_reason_non_compliant",
      text: "It’s non-compliant (or suspected to be)",
      value: true,
      disable_ghost: true,
      conditional: { html: non_compliant_details_html(form) },
      attributes: { class: "js-mutually-exclusive__item", data: { "mutually-exclusive-set-id": "reported-set" } }
    }
  end

  def reported_safe_and_compliant_checkbox
    {
      key: "reported_reason_safe_and_compliant",
      text: "It’s safe and compliant",
      hint: { text: "Help other market surveillance authorities avoid testing the same product again" },
      value: true,
      disable_ghost: true,
      attributes: { class: "js-mutually-exclusive__item", data: { "mutually-exclusive-set-id": "safe-set" } }
    }
  end
end
