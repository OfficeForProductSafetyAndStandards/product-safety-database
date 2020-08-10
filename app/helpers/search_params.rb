# frozen_string_literal: true

class SearchParams
  include ActiveModel::Model

  SORT_BY_OPTIONS = [
    NEWEST   = "newest",
    OLDEST   = "oldest",
    RECENT   = "recent",
    RELEVANT = "relevant"
  ].freeze

  attr_accessor :allegation,
                :case_owner_is_me,
                :case_owner_is_someone_else,
                :case_owner_is_someone_else_id,
                :created_by_me,
                :created_by_someone_else,
                :created_by_someone_else_id,
                :direction,
                :enquiry,
                :project,
                :q,
                :sort,
                :status_open,
                :status_closed,
                :coronavirus_related_only

  attr_writer :sort_by

  # ActionController::Parameters#each_key is not implemented in Rails 5.2 but is implemented in 6.0
  def initialize(attributes = {})
    attributes.keys.each { |name| class_eval { attr_accessor name } } # Add any additional query attributes to the model
    super(attributes)
  end

  def sort_by
    @sort_by || RECENT
  end

  def sorting_params
    case sort_by
    when NEWEST
      { created_at: "desc" }
    when OLDEST
      { updated_at: "asc" }
    when RECENT
      { updated_at: "desc" }
    when RELEVANT
      {}
    else
      { updated_at: "desc" }
    end
  end

  def sort_by_items(with_relevant_option: false)
    items = [
      { text: "Most recently updated",  value: RECENT, unchecked_value: "unchecked" },
      { text: "Least recently updated", value: OLDEST, unchecked_value: "unchecked" },
      { text: "Most recently created",  value: NEWEST, unchecked_value: "unchecked" }
    ]

    if with_relevant_option
      items.unshift(text: "Relevance", value: RELEVANT, unchecked_value: "unchecked")
    end

    items
  end
end
