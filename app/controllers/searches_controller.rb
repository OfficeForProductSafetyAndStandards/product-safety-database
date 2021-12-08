class SearchesController < ApplicationController
  include InvestigationsHelper

  def show
    @search = SearchParams.new(query_params)

    store_previous_search_params

    if @search.q.blank?
      redirect_to investigations_path(previous_search_params)
    else
      @answer = search_for_investigations(20)
      @investigations = @answer.records(includes: [{ owner_team: :organisation, owner_user: :organisation }, :products])
    end
  end
end
