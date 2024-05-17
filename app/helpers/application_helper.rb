module ApplicationHelper
  include Pagy::Frontend

  def page_title(title, errors: false)
    title = "Error: #{title}" if errors
    content_for(:page_title, title)
  end

  # The map_errors parameters can be used to link error messages for multi-answer
  # so they focus on a specific attribute option when clicked.
  # Eg: "map_errors: { colours: :red }" will cause validation errors messages for
  # "colours" in the error summary to link to "#red" instead of to "#colours".
  def error_summary(errors, ordered_attributes = [], map_errors: {})
    return unless errors.any?

    ordered_errors = ActiveSupport::OrderedHash.new
    ordered_attributes.map { |attr| ordered_errors[attr] = [] }

    errors.map do |error|
      next if error.blank? || error.message.blank?

      href = map_errors[error.attribute] || error.attribute
      href = "##{href}"

      # Errors for attributes that are not included in the ordered list will be
      # added at the end after the errors for ordered attributes.
      if ordered_errors[error.attribute]
        ordered_errors[error.attribute] << { text: error.message, href: }
      else
        ordered_errors[error.attribute] = [{ text: error.message, href: }]
      end
    end
    error_list = ordered_errors.values.flatten.compact

    govukErrorSummary(titleText: "There is a problem", errorList: error_list)
  end

  def govuk_hr
    tag.hr(class: "govuk-section-break govuk-section-break--m govuk-section-break--visible")
  end

  def markdown(text)
    rc = Redcarpet::Markdown.new(Redcarpet::Render::HTML)
    sanitized_input = sanitize(text, tags: %w[br])
    rc.render(sanitized_input).html_safe
  end

  # def replace_uploaded_file_field(form, field_name, label:, label_classes: "govuk-label--m")
  #   # binding.pry
  #   existing_uploaded_file_id = form.hidden_field "existing_#{field_name}_file_id"
  #   file_upload_field         = form.govuk_file_upload(field_name, label:, label_classes:)
  #   uploaded_file             = form.object.public_send(field_name)
  #
  #   return existing_uploaded_file_id.to_s + file_upload_field.to_s + render(partial: "active_storage/blobs/blob", locals: { blob: uploaded_file }) if uploaded_file.present?
  #
  #   existing_uploaded_file_id.to_s + file_upload_field.to_s
  # end
  def replace_uploaded_file_field(form, field_name, label:, label_classes: "govuk-label--m")
    existing_uploaded_file_id = existing_uploaded_file_field(form, field_name)
    file_upload_field         = file_upload_field(form, field_name, label, label_classes)
    uploaded_file             = form.object.public_send(field_name)

    file_fields = existing_uploaded_file_id + file_upload_field
    return file_fields + render_uploaded_file_partial(uploaded_file) if uploaded_file.present?

    file_fields
  end

  def existing_uploaded_file_field(form, field_name)
    form.hidden_field("existing_#{field_name}_file_id").to_s
  end

  def file_upload_field(form, field_name, label, label_classes)
    form.govuk_file_upload(field_name, label:, label_classes:).to_s
  end

  def render_uploaded_file_partial(uploaded_file)
    render(partial: "active_storage/blobs/blob", locals: { blob: uploaded_file })
  end

  def date_or_recent_time_ago(datetime)
    24.hours.ago < datetime ? "#{time_ago_in_words(datetime)} ago".capitalize : datetime.to_formatted_s(:govuk)
  end

  def psd_abbr(title: true)
    tag.abbr "PSD", title: title ? "Product Safety Database" : nil
  end
end
