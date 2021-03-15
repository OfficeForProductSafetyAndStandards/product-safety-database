class SearchesController < ApplicationController
  include InvestigationsHelper

  def show
    params_to_save = params.dup
    params_to_save.delete(:sort_by) if params[:sort_by] == SearchParams::RELEVANT

    if params[:override_sort_by]
      params[:sort_by] = params[:override_sort_by]
    end

    @search = SearchParams.new(query_params)
    session[:previous_search_params] = @search.serializable_hash

    if @search.q.blank?
      redirect_to investigations_path(previous_search_params)
    else
      @answer = search_for_investigations(20)
      @investigations = @answer.records(includes: [{ owner_team: :organisation, owner_user: :organisation }, :products])
    end
  end
end
