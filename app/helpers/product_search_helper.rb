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

  def get_owner_filter(user)
    return if @search.case_owner == "all"

    if (@search.case_owner == "my_team" || @search.case_owner == "me")
      compute_included_terms(user)
    end
  end

  def get_status_filter
    if @search.case_status == "open_only"
      { term: { "investigations.is_closed" => "false" } }
    end
  end

  def compute_excluded_terms(user)
    format_owner_terms([user.id])
  end

  def compute_included_terms(user)
    owners = []

    case @search.case_owner
    when "me"
      owners << user.id
    when "my_team"
      owners += user_ids_from_team(user.team)
    when "others"
      owners += other_owner_ids
    end

    format_owner_terms(owners.uniq)
  end

  def format_owner_terms(owner_array)
    owner_array.map do |a|
      { match: { "investigations.owner_id" => a } }
    end
  end

  def user_ids_from_team(team)
    [team.id] + team.users.map(&:id)
  end
end
