# frozen_string_literal: true

class SearchParams
  include ActiveModel::Model
  include ActiveModel::Attributes
  include ActiveModel::Serialization

  SORT_BY_OPTIONS = [
    NEWEST   = "newest",
    OLDEST   = "oldest",
    RECENT   = "recent",
    RELEVANT = "relevant",
    NAME     = "name"
  ].freeze

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
  attribute :page, :integer
  attribute :teams_with_access, default: "all"
  attribute :teams_with_access_other_id
  attribute :hazard_type

  def selected_sort_by
    if sort_by.blank?
      return RELEVANT if q.present?

      return RECENT
    end
    sort_by
  end

  def sorting_params
    case sort_by
    when NEWEST
      { created_at: "desc" }
    when OLDEST
      { updated_at: "asc" }
    when RECENT
      { updated_at: "desc" }
    else
      { updated_at: "desc" }
    end
  end

  def sort_by_items(with_relevant_option: false)
    items = [
      ["Recent updates", RECENT],
      ["Oldest updates", OLDEST],
      ["Newest cases", NEWEST]
    ]
    items.unshift(["Relevance", RELEVANT]) if with_relevant_option
    items
  end
end
