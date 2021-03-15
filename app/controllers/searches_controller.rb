class SearchesController < ApplicationController
  include InvestigationsHelper

  def show
    if params[:override_sort_by]
      params[:sort_by] = params[:override_sort_by]
    end

    @search = SearchParams.new(query_params)

    params_to_save = @search.serializable_hash
    params_to_save.delete(:sort_by) if params[:sort_by] == SearchParams::RELEVANT
    session[:previous_search_params] = params_to_save

    if @search.q.blank?
      redirect_to investigations_path(previous_search_params)
    else
      @answer = search_for_investigations(20)
      @investigations = @answer.records(includes: [{ owner_team: :organisation, owner_user: :organisation }, :products])
    end
  end
end
