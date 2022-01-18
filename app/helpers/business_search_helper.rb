module BusinessSearchHelper
  include SearchHelper

  def set_search_params
    @search = SearchParams.new(query_params)
    @search.q.strip! if @search.q
  end
end
