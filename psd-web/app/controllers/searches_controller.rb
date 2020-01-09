class SearchesController < ApplicationController
  include InvestigationsHelper

  def show
    set_search_params
    @answer = search_for_investigations(20)
    records = Investigation.eager_load(:products, :source).where(id: @answer.results.map(&:_id)).decorate
    @results = @answer.results.map { |r| r.merge(record: records.detect { |rec| rec.id.to_s == r._id }) }
    @investigations = @answer.records
    @sort_by_relevant_as_hidden_field = false
    render "investigations/index"
  end
end
