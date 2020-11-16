module ApplicationHelper
  def page_title(title, errors: false)
    title = "Error: #{title}" if errors
    content_for(:page_title, title)
  end

  def error_summary(errors, ordered_attributes = [])
    return unless errors.any?

    ordered_errors = ActiveSupport::OrderedHash.new
    ordered_attributes.map { |attr| ordered_errors[attr] = [] }

    errors.map do |attribute, error|
      next if error.blank?

      # Errors for attributes that are not included in the ordered list will be
      # added at the end after the errors for ordered attributes.
      if ordered_errors[attribute]
        ordered_errors[attribute] << { text: error, href: "##{attribute}" }
      else
        ordered_errors[attribute] = [{ text: error, href: "##{attribute}" }]
      end
    end
    error_list = ordered_errors.values.flatten.compact

    govukErrorSummary(titleText: "There is a problem", errorList: error_list)
  end

  def govuk_hr
    tag(:hr, class: "govuk-section-break govuk-section-break--m govuk-section-break--visible")
  end

  def markdown(text)
    rc = Redcarpet::Markdown.new(Redcarpet::Render::HTML)
    sanitized_input = sanitize(text, tags: %w[br])
    rc.render(sanitized_input).html_safe
  end

  def replace_uploaded_file_field(form, field_name, label:, label_classes: "govuk-label--m")
    existing_uploaded_file_id = form.hidden_field "existing_#{field_name}_file_id"
    file_upload_field         = form.govuk_file_upload(field_name, label: label, label_classes: label_classes)
    uploaded_file             = form.object.public_send(field_name)

    return safe_join([existing_uploaded_file_id, file_upload_field]) if uploaded_file.blank?

    safe_join(
      [
        existing_uploaded_file_id,
        render(uploaded_file),
        govukDetails(summaryText: "Replace this file", html: file_upload_field)
      ]
    )
  end
end
