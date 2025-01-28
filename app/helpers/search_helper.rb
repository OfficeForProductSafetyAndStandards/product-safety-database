module SearchHelper
  def search_params
    { query: params[:q], sort_by: sort_column, direction: sort_direction }
  end

  def filter_params(user)
    # Default empty filter params. To be overridden by the controller.
  end

  def get_owner_filter(user)
    return if @search.case_owner == "all"

    if %w[my_team me].include?(@search.case_owner)
      compute_included_terms(user)
    end
  end

  def compute_included_terms(user)
    owners = []

    case @search.case_owner
    when "me"
      owners << user.id
    when "my_team"
      owners += user_ids_from_team(user.team)
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
