module SortByHelper
  SORT_BY_VALUES = [
    SORT_BY_RELEVANT = "relevant".freeze,
    SORT_BY_NAME     = "name".freeze,
    SORT_BY_CREATED_AT = "created_at".freeze,
    SORT_BY_UPDATED_AT = "updated_at".freeze
  ].freeze

  SORT_DIRECTIONS = [
    SORT_DIRECTION_DEFAULT = nil,
    SORT_DIRECTION_ASC     = "asc".freeze,
    SORT_DIRECTION_DESC    = "desc".freeze
  ].freeze

  class SortByItem
    class UnpermittedSortParameterError < StandardError; end

    attr_reader :text, :value, :direction

    def initialize(text, value, direction)
      raise UnpermittedSortParameterError unless SORT_BY_VALUES.include?(value)
      raise UnpermittedSortParameterError unless SORT_DIRECTIONS.include?(direction)

      @text = text
      @value = value
      @direction = direction
    end
  end

  def render_sort_by(form, sort_by_items, selected_value, sort_direction = SORT_DIRECTION_DEFAULT, custom_classes = nil)
    render "application/sort_dropdown",
           form:,
           sort_by_items:,
           selected_value:,
           sort_direction:,
           custom_classes:
  end

  def url_for_sort_by(sort_by_item)
    new_params = request.params.dup
    new_params.delete(:sort_dir) if sort_by_item.direction.blank?
    new_params.merge!({ sort_by: sort_by_item.value, sort_dir: sort_by_item.direction }.compact)
    url_for(new_params)
  end

  def active_sort_by_item?(sort_by_item, selected_value, selected_direction)
    sort_by_item.value == selected_value && (selected_direction.blank? || sort_by_item.direction == selected_direction)
  end

  def options_for_sort_by(sort_by_items, selected_value, selected_direction = SORT_DIRECTION_DEFAULT)
    safe_join(sort_by_items.map do |sort_by_item|
      active = active_sort_by_item?(sort_by_item, selected_value, selected_direction)
      tag.option(sort_by_item.text, selected: active, data: { url: url_for_sort_by(sort_by_item) })
    end)
  end

  def definition_list_items_for_sort_by(sort_by_items, selected_value, selected_direction = SORT_DIRECTION_DEFAULT)
    safe_join(sort_by_items.map do |sort_by_item|
      active = active_sort_by_item?(sort_by_item, selected_value, selected_direction)
      tag.dd(link_to(safe_join([
        active.presence && tag.span("Active: ", class: "govuk-visually-hidden"),
        sort_by_item.text
      ]), url_for_sort_by(sort_by_item)), class: active.presence && "opss-dl-select__active")
    end)
  end
end
