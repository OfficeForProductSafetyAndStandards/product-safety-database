module GovukCheckboxHelper
  def govukCheckboxes(items: [], classes: "", formGroup: {}, attributes: {}, describedBy: "", fieldset: {}, hint: nil, errorMessage: nil)
    attributes[:class] = "govuk-checkboxes #{classes}"

    # a record of other elements that we need to associate with the input using
    # aria-describedby – for example hints or error messages -#}
    describedBy = fieldset[:describedBy] || describedBy

    idPrefix = ""

    # Do any of the items have conditional HTML associated?
    isConditional = items.detect { |item| item.dig(:conditional, :html) }

    # Capture the HTML so we can optionally nest it in a fieldset
    inner_html = capture do
      html = ""

      if hint

        hintId = idPrefix + "-hint"
        describedBy += " #{hintId}"

        html += govukHint(
          id: hintId,
          classes: hint[:classes],
          attributes: hint[:attributes],
          html: hint[:html],
          text: hint[:text]
        )
      end

      if errorMessage
        errorId = idPrefix + "-error"
        describedBy += " #{errorId}"

        html += govukErrorMessage(
          id: errorId,
          classes: errorMessage[:classes],
          attributes: errorMessage[:attributes],
          html: errorMessage[:html],
          text: errorMessage[:text],
          visuallyHiddenText: errorMessage[:visuallyHiddenText]
        )
      end

      html += tag.div attributes do
        items.each do |item|
          item_html = capture do
            tag.div class: "govuk-checkboxes__item" do
              concat tag.input class: "govuk-checkboxes__input", id: item[:id], name: item[:name], type: "checkbox", value: item[:value]

              concat govukLabel(
                classes: "govuk-checkboxes__label",
                text: item[:text],
                for: item[:id]
              )
            end
          end

          concat item_html
        end
      end

      html.html_safe
    end

    form_group_classes = "govuk-form-group"
    form_group_classes += " govuk-form-group--error" if errorMessage
    form_group_classes += " #{formGroup[:classes]}" if formGroup[:classes]

    tag.div class: form_group_classes do
      govukFieldset(
        describedBy: describedBy,
        classes: fieldset[:classes],
        attributes: fieldset[:attributes],
        legend: fieldset[:legend]
      ) do
        inner_html
      end
    end
  end
end
