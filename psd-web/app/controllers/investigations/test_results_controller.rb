class Investigations::TestResultsController < ApplicationController
  def show
    @investigation = Investigation.find_by(pretty_id: params[:investigation_pretty_id])
    authorize @investigation, :view_non_protected_details?
    @test = @investigation.test_results.find(params[:id]).decorate
  end
end
