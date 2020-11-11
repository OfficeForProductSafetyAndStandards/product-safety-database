module ApplicationHelper
  def page_title(title, errors: false)
    title = "Error: #{title}" if errors
    content_for(:page_title, title)
  end

  def error_summary(errors)
    return unless errors.any?

    error_list = errors.map { |attribute, error| error ? { text: error, href: "##{attribute}" } : nil }.compact
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
