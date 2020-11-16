class ApplicationFormBuilder < ActionView::Helpers::FormBuilder
  def govuk_date_input(attribute, legend:, hint: nil, classes: "govuk-fieldset__legend--m")
    if object.errors.include?(attribute)
      error_message = {
        text: object.errors.full_messages_for(attribute).first
      }
    end

    hint = { text: hint } if hint

    input_classes = " govuk-input--error" if object.errors.include?(attribute)

    @template.render "components/govuk_date_input",
                     id: "#{attribute}-fieldset",
                     errorMessage: error_message,
                     hint: hint,
                     fieldset: {
                       legend: {
                         classes: classes,
                         text: legend
                       }
                     },
                     items: [
                       {
                         classes: "govuk-input--width-2#{input_classes}",
                         label: "Day",
                         id: attribute,
                         name: "#{input_name(attribute)}[day]",
                         value: object.public_send(attribute)&.day
                       },
                       {
                         classes: "govuk-input--width-2#{input_classes}",
                         label: "Month",
                         name: "#{input_name(attribute)}[month]",
                         value: object.public_send(attribute)&.month
                       },
                       {
                         classes: "govuk-input--width-4#{input_classes}",
                         label: "Year",
                         name: "#{input_name(attribute)}[year]",
                         value: object.public_send(attribute)&.year
                       }
                     ]
  end

  def govuk_text_area(attribute, label:, label_classes: "govuk-label--m", hint: nil, attributes: {})
    if object.errors.include?(attribute)
      error_message = {
        text: object.errors.full_messages_for(attribute).first
      }
    end

    hint = { text: hint } if hint

    @template.render "components/govuk_textarea",
                     label: {
                       text: label,
                       classes: label_classes
                     },
                     hint: hint,
                     name: input_name(attribute),
                     id: attribute.to_s,
                     value: object.public_send(attribute),
                     errorMessage: error_message,
                     attributes: attributes
  end

  def govuk_input(attribute, label:, label_classes: nil, classes: nil, hint: nil)
    if object.errors.include?(attribute)
      error_message = {
        text: object.errors.full_messages_for(attribute).first
      }
    end

    hint = { text: hint } if hint

    @template.render "components/govuk_input",
                     label: {
                       text: label,
                       classes: label_classes.to_s
                     },
                     hint: hint,
                     name: input_name(attribute),
                     id: attribute.to_s,
                     classes: classes,
                     value: object.public_send(attribute),
                     errorMessage: error_message
  end

  def govuk_file_upload(attribute, label:, hint: nil, label_classes: nil, classes: nil)
    # Set the form's enctype attribute to multipart/form-data so that the file
    # will get uploaded.
    self.multipart = true

    if object.errors.include?(attribute)
      error_message = {
        text: object.errors.full_messages_for(attribute).first
      }
    end

    @template.govukFileUpload(
      id: attribute,
      name: input_name(attribute),
      errorMessage: error_message,
      classes: classes,
      hint: {
        text: hint
      },
      label: {
        text: label,
        classes: label_classes.to_s
      }
    )
  end

  def govuk_select(attribute, label:, label_classes: "", items:, hint: nil)
    if object.errors.include?(attribute)
      error_message = {
        text: object.errors.full_messages_for(attribute).first
      }
    end

    @items = items

    hint = { text: hint } if hint

    # Set item as selected if the value matches the method from the model
    @items.each_with_index do |item, _index|
      item[:selected] = true if object.public_send(attribute).to_s == item[:value].to_s
    end

    @template.render "components/govuk_select",
                     id: attribute.to_s,
                     name: input_name(attribute),
                     label: { text: label, classes: label_classes.to_s },
                     hint: hint,
                     items: @items,
                     errorMessage: error_message
  end

  def govuk_checkboxes(attribute, legend:, items:, hint: nil)
    if object.errors.include?(attribute)
      error_message = {
        text: object.errors.full_messages_for(attribute).first
      }
    end

    @items = items

    # Set item as checked if the value matches the method from the model
    @items.each_with_index do |item, index|
      item[:checked] = true if object.public_send(attribute).to_a.include?(item[:value].to_s)

      item[:name] = "#{input_name(attribute)}[]"
      # item[:value] = "1"

      item[:id] = if index.zero?
                    # First item should have the ID of the attribute, so that it gets
                    # focused when the error message anchor link is clicked.
                    attribute.to_s
                  else
                    "#{attribute}-#{index}"
                  end
    end

    hint = { text: hint } if hint

    @template.govukCheckboxes(
      errorMessage: error_message,
      items: @items,
      hint: hint,
      fieldset: {
        legend: {
          html: legend,
          classes: "govuk-fieldset__legend--m"
        }
      }
    )
  end

  def govuk_radios(attribute, legend:, legend_classes: "govuk-fieldset__legend--m", classes: "", items:)
    if object.errors.include?(attribute)
      error_message = {
        text: object.errors.full_messages_for(attribute).first
      }
    end

    @items = items

    # Set item as checked if the value matches the method from the model
    @items.each_with_index do |item, index|
      item[:checked] = true if object.public_send(attribute) == item[:value].to_s

      item[:id] = if index.zero?
                    # First item should have the ID of the attribute, so that it gets
                    # focused when the error message anchor link is clicked.
                    attribute.to_s
                  else
                    "#{attribute}-#{index}"
                  end
    end

    @template.render "components/govuk_radios",
                     name: input_name(attribute),
                     errorMessage: error_message,
                     items: @items,
                     classes: classes,
                     fieldset: {
                       legend: {
                         text: legend,
                         classes: legend_classes
                       }
                     }
  end

private

  def input_name(attribute)
    "#{@object_name}[#{attribute}]"
  end
end
