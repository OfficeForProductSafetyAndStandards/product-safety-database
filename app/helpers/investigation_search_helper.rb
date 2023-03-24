module InvestigationSearchHelper
  include SearchHelper

  def search_query(user)
    @search.q.strip! if @search.q
    OpensearchQuery.new(@search.q, filter_params(user), @search.sorting_params, nested: nested_filters(user))
  end

private

  def nested_filters(user)
    return [] if @search.teams_with_access == "all"

    [{ nested: { path: :teams_with_access, query: teams_with_access_query(user) } }]
  end

  def teams_with_access_query(user)
    query = {}

    query[:must] = { terms: { "teams_with_access.id" => teams_with_access(user) } } if @search.teams_with_access == "my_team" || other_team_with_access_specified?
    query[:must_not] = { term: { "teams_with_access.id" => user.team.id } } if @search.teams_with_access == "other"

    query.blank? ? {} : { bool: query }
  end

  def teams_with_access(user)
    return [user.team.id] if @search.teams_with_access == "my_team"
    return [@search.teams_with_access_other_id] if other_team_with_access_specified?
  end

  def other_team_with_access_specified?
    @search.teams_with_access == "other" && @search.teams_with_access_other_id.present?
  end

  def filter_params(user)
    filters_to_apply = [
      get_type_filter,
      get_status_filter,
      get_creator_filter(user),
      get_owner_filter(user),
      get_serious_and_high_risk_filter,
      get_hazard_type_filter
    ].compact

    { must: filters_to_apply }
  end

  def get_status_filter
    return if @search.case_status == "all"

    is_closed = @search.case_status == "closed"
    { term: { is_closed: } }
  end

  def get_serious_and_high_risk_filter
    if @search.priority == "serious_and_high_risk_level_only"
      { terms: { risk_level: Investigation.risk_levels.values_at(:serious, :high) } }
    end
  end

  def get_type_filter
    return if @search.case_type == "all"

    case @search.case_type
    when "allegation"
      types = ["Investigation::Allegation"]
    when "project"
      types = ["Investigation::Project"]
    when "enquiry"
      types = ["Investigation::Enquiry"]
    end

    { terms: { type: types } }
  end

  def get_hazard_type_filter
    return if @search.hazard_type.blank?

    { term: { hazard_type: @search.hazard_type } }
  end

  def get_owner_filter(user)
    return { bool: { should: [], must_not: [] } } if @search.case_owner == "all"
    return { bool: { should: [], must_not: compute_excluded_terms(user) } } if @search.case_owner == "others" && @search.case_owner_is_someone_else_id.blank?

    { bool: { should: compute_included_terms(user), must_not: [] } }
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
    return { bool: { should: [], must_not: [] } } if @search.created_by == "all"
    return { bool: { should: [], must_not: { terms: { creator_id: user.team.user_ids } } } } if @search.created_by == "others" && @search.created_by_other_id.blank?

    { bool: { should: format_creator_terms(selected_team_creator(user)), must_not: [] } }
  end

  def selected_team_creator(user)
    return [user.id]                     if @search.created_by == "me"
    return user_ids_from_team(user.team) if @search.created_by == "my_team"

    if @search.created_by == "others" && @search.created_by_other_id
      if (team = Team.find_by(id: @search.created_by_other_id))
        user_ids_from_team(team)
      else
        [@search.created_by_other_id]
      end
    end
  end

  def format_creator_terms(creator_array)
    creator_array.map do |a|
      { term: { creator_id: a } }
    end
  end

  def user_ids_from_team(team)
    [team.id] + team.users.map(&:id)
  end
end
