module GovukCheckboxHelper
  def govukCheckboxes(items: [], classes: "", formGroup: {}, attributes: {}, describedBy: "", fieldset: {}, hint: nil, errorMessage: nil)

    attributes[:class] = "govuk-checkboxes #{classes}"


    # a record of other elements that we need to associate with the input using
    # aria-describedby – for example hints or error messages -#}
    describedBy = fieldset[:describedBy] || describedBy


    # Do any of the items have conditional HTML associated?
    isConditional = items.detect {|item| item.dig(:conditional, :html) }

    # Capture the HTML so we can optionally nest it in a fieldset
    inner_html = capture do

      if hint

        hintId = idPrefix + '-hint'
        describedBy += " #{hintId}"

        concat govukHint(
          id: hintId,
          classes: hint[:classes],
          attributes: hint[:attributes],
          html: hint[:html],
          text: hint[:text]
        )
      end

      if errorMessage
        errorId = idPrefix + '-error'
        describedBy += " errorId"

        concat govukErrorMessage(
          id: errorId,
          classes: params.errorMessage.classes,
          attributes: params.errorMessage.attributes,
          html: params.errorMessage.html,
          text: params.errorMessage.text,
          visuallyHiddenText: params.errorMessage.visuallyHiddenText
        )
      end

      tag.div attributes do

        items.each do |item|

          item_html = capture do
            tag.div class: "govuk-checkboxes__item" do
              concat tag.input class: "govuk-checkboxes__input", id: item[:id], name: item[:name], type: "checkbox", value: item[:value]

              concat govukLabel(
                classes: 'govuk-checkboxes__label',
                text: item[:text],
                for: item[:id]
              )
            end
          end

          concat item_html

        end

      end
    end


    tag.div class: "govuk-form-group #{formGroup[:classes]}" do

        govukFieldset(
          describedBy: describedBy,
          classes: fieldset[:classes],
          attributes: fieldset[:attributes],
          legend: fieldset[:legend]
        ) do
          inner_html
        end

      # inner_html
      # if fieldset
      #   concat govukFieldset(
      #     describedBy: describedBy,
      #     classes: fieldset[:classes],
      #     attributes: fieldset[:attributes],
      #     legend: fieldset[:legend]
      #   )
      # else
      #   concat inner_html
      # end

    end

  end
end
