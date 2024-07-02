class SearchesController < ApplicationController
  include InvestigationsHelper

  def show
    @search = SearchParams.new(query_params.except(:page_name))
    if @search.q.blank?
      redirect_to notifications_path(query_params.except(:page_name))
    else
      ahoy.track "Performed search", { query: query_params[:q] }
      @pagy, @answer = pagy_searchkick(notifications_search)
      @count = @pagy.count
      @investigations = @answer.includes([{ owner_team: :organisation, owner_user: :organisation }, :products])
    end
  end

private

  def notifications_search
    new_opensearch_for_investigations(20, paginate: true)
  end
end
