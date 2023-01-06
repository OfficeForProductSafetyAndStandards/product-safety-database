module ProductSearchHelper
  include SearchHelper

  def filter_params(user)
    must_match_filters = [
      get_hazard_filter,
      get_status_filter,
      get_retired_filter
    ].compact

    should_match_filters = [
      get_owner_filter(user)
    ].compact.flatten

    { must: must_match_filters, should: should_match_filters }
  end

  def get_hazard_filter
    if params[:hazard_type].present?
      { match: { "investigations.hazard_type" => @search.hazard_type } }
    end
  end

  def get_status_filter
    if @search.case_status == "open_only"
      { term: { "investigations.is_closed" => "false" } }
    end
  end

  def get_retired_filter
    return if @search.retired_status == "all"

    if @search.retired_status == "active" || @search.retired_status.blank?
      return { term: { "is_retired" => false } }
    end

    if @search.retired_status == "retired"
      { term: { "is_retired" => true } }
    end
  end
end
