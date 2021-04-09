class SearchesController < ApplicationController
  include InvestigationsHelper

  def show
    @search = SearchParams.new(search_params)

    store_previous_search_params

    if @search.q.blank?
      redirect_to investigations_path(previous_search_params)
    else
      @answer = search_for_investigations(20)
      @investigations = @answer.records(includes: [{ owner_team: :organisation, owner_user: :organisation }, :products])
    end
  end

private

  def search_params
    query_params.except(:created_by_team_0).tap do |p|
      p[:sort_by] = SearchParams::RELEVANT if p[:q].present?
    end
  end
end
