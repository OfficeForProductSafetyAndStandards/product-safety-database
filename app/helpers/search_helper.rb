module SearchHelper
  def set_search_params
    @search = SearchParams.new(query_params.except(:page_name))
  end

  def search_params
    { query: params[:q], sort_by: sort_column, direction: sort_direction }
  end

  def search_query(user)
    @search.q.strip! if @search.q
    OpensearchQuery.new(@search.q, filter_params(user), sorting_params)
  end

  def query_params
    params.permit(:q, :sort_by, :sort_dir, :direction, :category, :retired_status, :page_name)
  end

  def sorting_params
    # Default empty sort params. To be overridden by the controller.
    # { "#{sort_column}": sort_direction }
  end

  def filter_params(user)
    # Default empty filter params. To be overridden by the controller.
  end

  def page_number
    params[:page].to_i > 500 ? "500" : params[:page]
  end

  def get_owner_filter(user)
    return if @search.case_owner == "all"

    if @search.case_owner == "my_team" || @search.case_owner == "me"
      compute_included_terms(user)
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
