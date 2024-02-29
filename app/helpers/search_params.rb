class SearchParams
  include ActiveModel::Model
  include ActiveModel::Attributes
  include ActiveModel::Serialization

  attribute :created_by, default: "all"
  attribute :created_by_other_id
  attribute :created_by_me, :boolean
  attribute :created_by_my_team, :boolean
  attribute :created_by_others, :boolean
  attribute :override_sort_by
  attribute :direction
  attribute :case_type, default: "all"
  attribute :allegation, :boolean
  attribute :project, :boolean
  attribute :notification, :boolean
  attribute :enquiry, :boolean
  attribute :q
  attribute :case_status, default: "open"
  attribute :case_status_open, :boolean
  attribute :case_status_closed, :boolean
  attribute :priority, default: "all"
  attribute :serious, :boolean
  attribute :high, :boolean
  attribute :medium, :boolean
  attribute :low, :boolean
  attribute :not_set, :boolean
  attribute :case_owner, default: "all"
  attribute :case_owner_me, :boolean
  attribute :case_owner_my_team, :boolean
  attribute :case_owner_other, :boolean
  attribute :case_owner_is_someone_else_id
  attribute :sort_by
  attribute :sort_dir
  attribute :page, :integer
  attribute :teams_with_access, default: "all"
  attribute :teams_with_access_my_team, :boolean
  attribute :teams_with_access_others, :boolean
  attribute :teams_with_access_other_id
  attribute :unsafe, :boolean
  attribute :unsafe_and_non_compliant, :boolean
  attribute :non_compliant, :boolean
  attribute :safe_and_compliant, :boolean
  attribute :hazard_type
  attribute :category
  attribute :page_name
  attribute :state
  attribute :retired_status
  attribute :id
  attribute :name
  attribute :product_code
  attribute :barcode
  attribute :created_from_date, :govuk_date
  attribute :created_to_date, :govuk_date
  Rails.application.config.hazard_constants["hazard_type"].each do |type|
    attribute type.parameterize.underscore.to_sym, :boolean
  end
  Business::BUSINESS_TYPES.each do |business_type|
    attribute business_type.parameterize.underscore.to_sym, :boolean
  end
  Country.all.each do |country|
    attribute country[0].parameterize.underscore.to_sym, :boolean
  end

  def selected_sort_by
    if sort_by.blank?
      return SortByHelper::SORT_BY_RELEVANT if q.present?

      return SortByHelper::SORT_BY_CREATED_AT if page_name == "team_cases" || page_name == "your_cases"

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
    return {} if selected_sort_by == SortByHelper::SORT_BY_RELEVANT

    { selected_sort_by => selected_sort_dir }
  end

  def sort_by_items(with_relevant_option: false)
    items = if page_name == "team_cases" || page_name == "your_cases"
              [
                SortByHelper::SortByItem.new("Newest notifications", SortByHelper::SORT_BY_CREATED_AT, SortByHelper::SORT_DIRECTION_DESC),
                SortByHelper::SortByItem.new("Oldest notifications", SortByHelper::SORT_BY_CREATED_AT, SortByHelper::SORT_DIRECTION_ASC),
                SortByHelper::SortByItem.new("Recent updates", SortByHelper::SORT_BY_UPDATED_AT, SortByHelper::SORT_DIRECTION_DESC),
                SortByHelper::SortByItem.new("Oldest updates", SortByHelper::SORT_BY_UPDATED_AT, SortByHelper::SORT_DIRECTION_ASC)
              ]
            else
              [
                SortByHelper::SortByItem.new("Recent updates", SortByHelper::SORT_BY_UPDATED_AT, SortByHelper::SORT_DIRECTION_DESC),
                SortByHelper::SortByItem.new("Oldest updates", SortByHelper::SORT_BY_UPDATED_AT, SortByHelper::SORT_DIRECTION_ASC),
                SortByHelper::SortByItem.new("Newest notifications", SortByHelper::SORT_BY_CREATED_AT, SortByHelper::SORT_DIRECTION_DESC),
                SortByHelper::SortByItem.new("Oldest notifications", SortByHelper::SORT_BY_CREATED_AT, SortByHelper::SORT_DIRECTION_ASC)
              ]
            end

    items.unshift(SortByHelper::SortByItem.new("Relevance", SortByHelper::SORT_BY_RELEVANT, SortByHelper::SORT_DIRECTION_DEFAULT)) if with_relevant_option
    items
  end

  def uses_expanded_filter_options?
    teams_with_access != "all" || created_by != "all" ||
      case_type != "all" || case_owner != "all" ||
      created_from_date.present? || created_to_date.present?
  end
end
