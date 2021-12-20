module SortByHelper
  def render_sort_by(form, sort_by_items, selected_value)
    render "application/sort_dropdown",
           form: form,
           sort_by_items: sort_by_items,
           selected_value: selected_value
  end

  def sort_by_url(sort_by_value)
    url_for(request.params.merge(sort_by: sort_by_value))
  end

  def sort_by_options(sort_by_items, selected_value)
    safe_join(sort_by_items.map do |(text, value)|
      tag.option(text, value: value, selected: value == selected_value, data: { url: sort_by_url(value) })
    end)
  end

  def sort_by_definition_list_items(sort_by_items, selected_value)
    safe_join(sort_by_items.map do |(text, value)|
      active = value == selected_value
      tag.dd(link_to(safe_join([
        active.presence && tag.span("Active: ", class: "govuk-visually-hidden"),
        text
      ]), sort_by_url(value)), class: active.presence && "opss-dl-select__active")
    end)
  end
end
