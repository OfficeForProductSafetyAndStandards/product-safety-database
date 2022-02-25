# frozen_string_literal: true

class SearchParams
  include ActiveModel::Model
  include ActiveModel::Attributes
  include ActiveModel::Serialization

  attribute :created_by, default: "all"
  attribute :created_by_other_id
  attribute :override_sort_by
  attribute :direction
  attribute :case_type, default: "all"
  attribute :q
  attribute :case_status, default: "open"
  attribute :priority, default: "all"
  attribute :case_owner, default: "all"
  attribute :case_owner_is_someone_else_id
  attribute :sort_by
  attribute :sort_dir
  attribute :page, :integer
  attribute :teams_with_access, default: "all"
  attribute :teams_with_access_other_id
  attribute :hazard_type

  def selected_sort_by
    if sort_by.blank?
      return SortByHelper::SORT_BY_RELEVANT if q.present?

      return SortByHelper::SORT_BY_UPDATED_AT
    end
    sort_by
  end

  def selected_sort_dir
    if sort_dir.blank?
      return SortByHelper::SORT_DIRECTION_DESC
    end
    
    sort_dir
  end

  def sorting_params
    sort_by_field = sort_by.blank? ? "updated_at" : sort_by
    sort_dir_value = sort_dir.blank? ? "desc" : sort_dir

    { sort_by_field => sort_dir_value }
  end

  def sort_by_items(with_relevant_option: false)
    items = [
      SortByHelper::SortByItem.new("Recent updates", SortByHelper::SORT_BY_UPDATED_AT, SortByHelper::SORT_DIRECTION_DESC),
      SortByHelper::SortByItem.new("Oldest updates", SortByHelper::SORT_BY_UPDATED_AT, SortByHelper::SORT_DIRECTION_ASC),
      SortByHelper::SortByItem.new("Newest cases", SortByHelper::SORT_BY_CREATED_AT, SortByHelper::SORT_DIRECTION_DESC),
      SortByHelper::SortByItem.new("Oldest cases", SortByHelper::SORT_BY_CREATED_AT, SortByHelper::SORT_DIRECTION_ASC)
    ]
    items.unshift(SortByHelper::SortByItem.new("Relevance", SortByHelper::SORT_BY_RELEVANT, SortByHelper::SORT_DIRECTION_DEFAULT)) if with_relevant_option
    items
  end

  def uses_expanded_filter_options?
    teams_with_access != "all" || created_by != "all" ||
      case_type != "all" || case_status != "open"
  end
end
