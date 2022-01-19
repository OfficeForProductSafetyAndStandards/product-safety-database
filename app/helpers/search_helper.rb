module SearchHelper
  def set_search_params
    @search = SearchParams.new(query_params)
  end

  def search_params
    { query: params[:q], sort_by: sort_column, direction: sort_direction }
  end

  def search_query(user)
    @search.q.strip! if @search.q
    OpensearchQuery.new(@search.q, filter_params(user), sorting_params)
  end

  def query_params
    params.permit(:q, :sort_by, :direction, :hazard_type)
  end

  def sorting_params
    # Default empty sort params. To be overridden by the controller.
    # { "#{sort_column}": sort_direction }
  end

  def filter_params(user)
    # Default empty filter params. To be overridden by the controller.
  end
end
