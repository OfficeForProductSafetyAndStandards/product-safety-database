class SearchesController < ApplicationController
  include InvestigationsHelper

  def show
    @search = SearchParams.new(query_params.except(:page_name))
    if @search.q.blank?
      redirect_to investigations_path(query_params.except(:page_name))
    else
      @answer = opensearch_for_investigations(20)
      @investigations = @answer.records(includes: [{ owner_team: :organisation, owner_user: :organisation }, :products])
    end
  end
end
