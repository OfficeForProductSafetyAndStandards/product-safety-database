module ProductSearchHelper
  include SearchHelper

  def filter_params(user)
    must_match_filters = [
      get_hazard_filter,
      get_status_filter
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
end
