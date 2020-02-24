module ApplicationHelper
  def title_for(any_active_record, title)
    return content_for(:page_title, title) unless any_active_record.errors.any?

    content_for(:page_title, "Error: #{title}")
  end

  def error_summary(errors)
    return unless errors.any?

    error_list = errors.map { |attribute, error| { text: error, href: "##{attribute}" } }
    govukErrorSummary(titleText: "There is a problem", errorList: error_list)
  end

  def govuk_hr
    tag(:hr, class: "govuk-section-break govuk-section-break--m govuk-section-break--visible")
  end

  def sortable(column, title = nil)
    title ||= column.titleize
    css_class = column == sort_column ? "current #{sort_direction}" : "unselected"
    direction = column == sort_column && sort_direction == "asc" ? "desc" : "asc"
    link_to title, query_params.merge(sort: column, direction: direction), class: "sort-link #{css_class}"
  end

  def markdown(text)
    rc = Redcarpet::Markdown.new(Redcarpet::Render::HTML)
    sanitized_input = sanitize(text, tags: %w(br))
    rc.render(sanitized_input).html_safe # rubocop:disable Rails/OutputSafety
  end
end
