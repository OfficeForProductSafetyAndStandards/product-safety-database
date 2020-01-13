class SearchesController < ApplicationController
  include InvestigationsHelper

  def show
    set_search_params
    @answer = search_for_investigations(20)
    @investigations = @answer.records(includes: [{ assignable: :organisation }, :products])
  end
end
