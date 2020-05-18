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
    rc.render(sanitized_input).html_safe # rubocop:disable Rails/OutputSafety
  end

  def permissions_hint(permission = "this")
    "Only teams added to the case can view #{permission}"
  end
end
