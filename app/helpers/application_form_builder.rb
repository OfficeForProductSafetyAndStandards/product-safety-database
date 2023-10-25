class ApplicationFormBuilder < ActionView::Helpers::FormBuilder
  def govuk_date_input(attribute, legend:, hint: nil, classes: "govuk-fieldset__legend--m")
    if object.errors.include?(attribute)
      error_message = {
        text: object.errors.full_messages_for(attribute).first
      }
    end

    hint = { text: hint } if hint

    input_classes = " govuk-input--error" if object.errors.include?(attribute)

    @template.govukDateInput(
      id: "#{attribute}-fieldset",
      errorMessage: error_message,
      hint:,
      fieldset: {
        legend: {
          classes:,
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
    )
  end

  def govuk_text_area(attribute, label:, label_classes: "govuk-label--m", hint: nil, attributes: {}, hint_classes: nil, classes: nil, rows: 5, described_by: nil, value: nil)
    if object.errors.include?(attribute)
      error_message = {
        text: object.errors.full_messages_for(attribute).first
      }
    end

    hint = { text: hint } if hint
    hint[:classes] = hint_classes if hint && hint_classes.present?

    @template.govukTextarea(
      label: {
        text: label,
        classes: label_classes
      },
      hint:,
      name: input_name(attribute),
      id: attribute.to_s,
      value: value || object.public_send(attribute),
      errorMessage: error_message,
      attributes:,
      classes:,
      rows:,
      described_by:
    )
  end

  def govuk_input(attribute, label: nil, value: nil, label_classes: nil, hint: nil, **kwargs)
    if object.errors.include?(attribute)
      error_message = {
        text: object.errors.full_messages_for(attribute).first
      }
    end

    label = { text: label, classes: label_classes.to_s } if label.is_a?(String)
    hint = { text: hint } if hint.is_a?(String)

    @template.govukInput(
      id: attribute.to_s,
      name: input_name(attribute),
      value: value || object.public_send(attribute),
      errorMessage: error_message,
      label:,
      hint:,
      **kwargs
    )
  end

  def govuk_file_upload(attribute, label:, hint: nil, label_classes: nil, classes: nil, attributes: {})
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
      classes:,
      hint: {
        text: hint
      },
      label: {
        text: label,
        classes: label_classes.to_s
      },
      attributes:
    )
  end

  def govuk_select(attribute, label:, items:, label_classes: "", hint: nil)
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

    @template.govukSelect(
      id: attribute.to_s,
      name: input_name(attribute),
      label: { text: label, classes: label_classes.to_s },
      hint:,
      items: @items,
      errorMessage: error_message
    )
  end

  def govuk_autocomplete(attribute, label:, label_classes: "", items: nil, choices: nil, hint: nil)
    if object.errors.include?(attribute)
      error_message = {
        text: object.errors.full_messages_for(attribute).first
      }
    end

    hint = { text: hint } if hint

    @items = items || choices.map { |choice| { value: choice, text: choice } }
    @items.unshift(value: nil, text: "")

    # Set item as selected if the value matches the method from the model
    @items.each_with_index do |item, _index|
      item[:selected] = true if object.public_send(attribute).to_s == item[:value].to_s
    end

    @template.govukSelect(
      id: attribute.to_s,
      name: input_name(attribute),
      label: { text: label, classes: label_classes.to_s },
      hint:,
      items: @items,
      errorMessage: error_message,
      show_all_values: true,
      is_autocomplete: true
    )
  end

  def govuk_checkboxes(attribute, legend:, items:, legend_classes: "govuk-fieldset__legend--m", hint: nil)
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
      hint:,
      fieldset: {
        legend: {
          html: legend,
          classes: legend_classes
        }
      }
    )
  end

  def govuk_radios(attribute, legend:, items:, legend_classes: "govuk-fieldset__legend--m", is_page_heading: false, fieldset: nil, **kwargs)
    if object.errors.include?(attribute)
      error_message = {
        text: object.errors.full_messages_for(attribute).first
      }
    end

    @items = items

    # Set item as checked if the value matches the method from the model
    @items.each_with_index do |item, index|
      selected_no = object.public_send(attribute) == false && ActiveRecord::Type::Boolean.new.cast(item[:value]) == false
      selected_yes = object.public_send(attribute) == true && ActiveRecord::Type::Boolean.new.cast(item[:value]) == true

      item[:checked] = (object.public_send(attribute) == item[:value].to_s) || selected_no || selected_yes

      item[:id] = if index.zero?
                    # First item should have the ID of the attribute, so that it gets
                    # focused when the error message anchor link is clicked.
                    attribute.to_s
                  else
                    "#{attribute}-#{index}"
                  end
    end

    if fieldset.nil?
      fieldset = {
        legend: {
          text: legend,
          classes: legend_classes,
          isPageHeading: is_page_heading
        }
      }
    end

    @template.govukRadios(
      name: input_name(attribute),
      errorMessage: error_message,
      items: @items,
      fieldset:,
      **kwargs
    )
  end

private

  def input_name(attribute)
    "#{@object_name}[#{attribute}]"
  end
end
