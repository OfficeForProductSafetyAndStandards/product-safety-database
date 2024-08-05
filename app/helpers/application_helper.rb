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

  def date_or_recent_time_ago(datetime)
    24.hours.ago < datetime ? "#{time_ago_in_words(datetime)} ago".capitalize : datetime.to_formatted_s(:govuk)
  end

  def psd_abbr(title: true)
    tag.abbr "PSD", title: title ? "Product Safety Database" : nil
  end
end
