module InvestigationSearchHelper
  include SearchHelper

  def search_query(user)
    ElasticsearchQuery.new(@search.q, filter_params(user), @search.sorting_params, nested: nested_filters(user))
  end

  def set_search_params
    params_to_save = params.dup
    params_to_save.delete(:sort_by) if params[:sort_by] == SearchParams::RELEVANT
    @search = SearchParams.new(query_params.except(:case_owner_is_team_0, :created_by_team_0))

    store_previous_search_params
  end

  def filter_params(user)
    filters = {}
    filters.merge!(get_type_filter)
    filters.merge!(merged_must_filters(user)) { |_key, current_filters, new_filters| current_filters + new_filters }
  end

  def nested_filters(user)
    filters = []

    return filters unless @search.teams_with_access == "my_team" || @search.teams_with_access == "other"

    teams_with_access = case @search.teams_with_access
                        when "my_team"
                          [user.team.id]
                        when "other"
                          [@search.teams_with_access_other_id]
                        else
                          []
                        end

    filters << {
      nested: {
        path: :teams_with_access,
        query: { bool: { must: { terms: { "teams_with_access.id" => teams_with_access } } } }
      }
    }

    filters
  end

  def merged_must_filters(user)
    must_filters = {
      must: [
        get_status_filter,
        { bool: get_creator_filter(user) },
        { bool: get_owner_filter(user) }
      ]
    }

    return must_filters if @search.priority == "all"

    case @search.priority
    when "coronavirus_related_only"
      must_filters[:must] << { term: { coronavirus_related: true } }
    when "serious_and_high_risk_level_only"
      must_filters[:must] << { terms: { risk_level: Investigation.risk_levels.values_at(:serious, :high) } }
    when "coronavirus_and_serious_and_high_risk"
      must_filters[:must] << { terms: { risk_level: Investigation.risk_levels.values_at(:serious, :high) } }
      must_filters[:must] << { term: { coronavirus_related: true } }
    end

    must_filters
  end

  def get_status_filter
    return if @search.case_status == "all"

    is_closed = @search.case_status == "closed"
    { term: { is_closed: is_closed } }
  end

  def get_type_filter
    return {} if @search.case_type == "all"

    case @search.case_type
    when "allegation"
      types = ["Investigation::Allegation"]
    when "project"
      types = ["Investigation::Project"]
    when "enquiry"
      types = ["Investigation::Enquiry"]
    end

    type = { type: types }
    { must: [{ terms: type }] }
  end

  def get_owner_filter(user)
    return { should: [], must_not: [] } if @search.case_owner == "all"
    return { should: [], must_not: compute_excluded_terms(user) } if @search.case_owner == "others" && @search.case_owner_is_someone_else_id.blank?

    { should: compute_included_terms(user), must_not: [] }
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

    # owners << user.id if @search.case_owner_is_me?
    # owners += my_team_id_and_its_user_ids(user) if @search.case_owner_is_my_team?
    # owners += other_owner_ids if @search.case_owner_is_someone_else?

    format_owner_terms(owners.uniq)
  end

  def other_owner_ids
    if (team = Team.find_by(id: @search.case_owner_is_someone_else_id))
      return user_ids_from_team(team)
    end

    [@search.case_owner_is_someone_else_id]
  end

  def format_owner_terms(owner_array)
    owner_array.map do |a|
      { term: { owner_id: a } }
    end
  end

  def get_creator_filter(user)
    return { should: [], must_not: [] } if @search.created_by == "all"
    return { should: [], must_not: { terms: { creator_id: user.team.user_ids } } } if @search.created_by == "others" && @search.created_by_other_id.blank?

    { should: format_creator_terms(checked_team_creators(user)), must_not: [] }
  end

  def checked_team_creators(user)
    ids = []

    ids << user.id                       if @search.created_by == "me"
    ids += user_ids_from_team(user.team) if @search.created_by == "my_team"

    if @search.created_by == "others" && @search.created_by_other_id
      if (team = Team.find_by(id: @search.created_by_other_id))
        ids += user_ids_from_team(team)
      else
        ids << @search.created_by_other_id
      end
    end

    ids
  end

  def someone_else_creators
    return [] unless params[:created_by_someone_else] == "checked"

    team = Team.find_by(id: params[:created_by_someone_else_id])
    team.present? ? user_ids_from_team(team) : [params[:created_by_someone_else_id]]
  end

  def format_creator_terms(creator_array)
    creator_array.map do |a|
      { term: { creator_id: a } }
    end
  end

  def user_ids_from_team(team)
    [team.id] + team.users.map(&:id)
  end

  def my_team_id_and_its_user_ids(user)
    [user.team_id] + user.team.user_ids - [user.id]
  end
end
