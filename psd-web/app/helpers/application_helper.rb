module ApplicationHelper
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

  def itens_for_govuk_date_input(form, attribute)
    dom_class = dom_class(form.object)
    name = ->(i) { "#{dom_class}[#{attribute}](#{i}i))" }
    id = ->(i) { "#{dom_class}_#{attribute}_#{i}i" }
    value = ->(date_part) { form.object.public_send(attribute)&.public_send(date_part) }
    [
      { name: name.(3), value: value.(:day),   classes: "govuk-input--width-2", label: "Day",   id: id.(3) },
      { name: name.(2), value: value.(:month), classes: "govuk-input--width-2", label: "Month", id: id.(2) },
      { name: name.(1), value: value.(:year),  classes: "govuk-input--width-4", label: "year",  id: id.(1) }
    ]
  end
end
