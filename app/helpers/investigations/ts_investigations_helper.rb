module Investigations::TsInvestigationsHelper
private

  def edit_page_heading_html(page_heading)
    render "investigations/why_reporting_form_heading", page_heading:
  end

  def edit_unsafe_details_html(form, hazard_types)
    render "investigations/why_reporting_form_unsafe_details", form:, hazard_types:
  end

  def non_compliant_details_html(form)
    form.govuk_text_area :non_compliant_reason,
                         label: { text: "Why is the product non-compliant?" },
                         hint: { text: "If the product has been involved in an incident include this additional information." },
                         max_chars: 10_000,
                         width: "three-quarters"
  end
end
