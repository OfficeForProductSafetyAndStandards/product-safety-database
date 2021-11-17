module InvestigationSearchHelper
  include SearchHelper

  def search_query(user)
    ElasticsearchQuery.new(@search.q, filter_params(user), @search.sorting_params, nested: nested_filters)
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

  def nested_filters
    filters = []

    if @search.filter_teams_with_access?
      filters << {
        nested: {
          path: :teams_with_access,
          query: { bool: { must: { terms: { "teams_with_access.id" => @search.teams_with_access_ids } } } }
        }
      }
    end

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

    if @search.coronavirus_related_only?
      must_filters[:must] << { term: { coronavirus_related: true } }
    end

    if @search.serious_and_high_risk_level_only?
      must_filters[:must] << { terms: { risk_level: Investigation.risk_levels.values_at(:serious, :high) } }
    end

    must_filters
  end

  def get_status_filter
    return unless @search.filter_status?

    { term: { is_closed: @search.is_closed? } }
  end

  def get_type_filter
    return {} if params[:allegation] == "unchecked" && params[:enquiry] == "unchecked" && params[:project] == "unchecked"

    types = []
    types << "Investigation::Allegation" if params[:allegation] == "checked"
    types << "Investigation::Enquiry" if params[:enquiry] == "checked"
    types << "Investigation::Project" if params[:project] == "checked"
    type = { type: types }
    { must: [{ terms: type }] }
  end

  def get_owner_filter(user)
    return { should: [], must_not: [] } if @search.no_owner_boxes_checked?
    return { should: [], must_not: compute_excluded_terms(user) } if @search.owner_filter_exclusive?

    { should: compute_included_terms(user), must_not: [] }
  end

  def compute_excluded_terms(user)
    format_owner_terms([user.id])
  end

  def compute_included_terms(user)
    owners = []
    owners << user.id if @search.case_owner_is_me?
    owners += my_team_id_and_its_user_ids(user) if @search.case_owner_is_my_team?
    owners += other_owner_ids if @search.case_owner_is_someone_else?

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
    return { should: [], must_not: [] } if @search.no_created_by_checked?
    return { should: [], must_not: { terms: { creator_id: user.team.user_ids } } } if @search.created_by_filter_exclusive?

    { should: format_creator_terms(checked_team_creators(user)), must_not: [] }
  end

  def checked_team_creators(user)
    ids = []

    ids << user.id                       if @search.created_by.me?
    ids += user_ids_from_team(user.team) if @search.created_by.my_team?

    if @search.created_by.someone_else? && @search.created_by.id.present?
      if (team = Team.find_by(id: @search.created_by.id))
        ids += user_ids_from_team(team)
      else
        ids << @search.created_by.id
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
    [user.team_id] + user.team.user_ids
  end
end
