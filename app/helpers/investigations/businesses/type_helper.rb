module Investigations::Businesses::TypeHelper
  def relationship_items(form)
    condition_html = form.govuk_input(
      :other_relationship,
      classes: "govuk-!-width-one-third",
      label: "Other type",
      label_classes: "govuk-visually-hidden"
    )

    BusinessInvestigationForm::BUSINESS_TYPES.map do |value, label|
      item = { text: label, value: value }
      item[:conditional] = { html: condition_html } if value.inquiry.other?
      item
    end
  end
end
