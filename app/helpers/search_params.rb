# frozen_string_literal: true

class SearchParams
  include ActiveModel::Model
  include ActiveModel::Attributes
  include ActiveModel::Serialization

  SORT_BY_OPTIONS = [
    NEWEST   = "newest",
    OLDEST   = "oldest",
    RECENT   = "recent",
    RELEVANT = "relevant"
  ].freeze

  attribute :allegation
  attribute :case_owner_is_me
  attribute :case_owner_is_someone_else
  attribute :case_owner_is_someone_else_id
  attribute :created_by_me
  attribute :created_by_someone_else
  attribute :created_by_someone_else_id
  attribute :override_sort_by
  attribute :direction
  attribute :enquiry
  attribute :project
  attribute :q
  attribute :sort
  attribute :status_open, :boolean
  attribute :status_closed, :boolean
  attribute :coronavirus_related_only, :boolean
  attribute :serious_and_high_risk_level_only
  attribute :sort_by

  attribute :teams_with_access, :teams_with_access_search_params, default: TeamsWithAccessSearchFormFields.new

  def teams_with_access_ids
    @teams_with_access_ids ||= teams_with_access.id
  end

  def filter_teams_with_access?
    teams_with_access_ids.any?
  end

  def attributes
    super
      .except("teams_with_access")
      .merge("teams_with_access" => teams_with_access.attributes)
  end

  def sort_by
    @override_sort_by || @sort_by || RECENT
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
