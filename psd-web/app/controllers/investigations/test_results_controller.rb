class Investigations::TestResultsController < ApplicationController
  def show
    @investigation = Investigation.find_by(pretty_id: params[:investigation_pretty_id])
    authorize @investigation, :view_non_protected_details?
    @test_result = @investigation.test_results.find(params[:id]).decorate
  end

  def edit
    @investigation = Investigation.find_by(pretty_id: params[:investigation_pretty_id]).decorate
    authorize @investigation, :update?
    @test_result = @investigation.test_results.find(params[:id])

    @file_blob = @test_result.documents.first.blob
  end

  def update
    @investigation = Investigation.find_by(pretty_id: params[:investigation_pretty_id]).decorate
    authorize @investigation, :update?
    @test_result = @investigation.test_results.find(params[:id])

    @test_result.set_dates_from_params(params[:test_result])
    @test_result.attributes = test_result_attributes

    if params[:test_result][:file][:file]

      # remove previous attachment
      @test_result.documents.first&.purge_later

      @test_result.documents.attach(params[:test_result][:file][:file])

      document = @test_result.documents.first
      document.blob.metadata[:description] = params[:test_result][:file][:description]
      document.blob.save

    end

    if @test_result.save

      document = @test_result.documents.first
      document.blob.metadata[:description] = params[:test_result][:file][:description]
      document.blob.save

      redirect_to investigation_test_result_path(@investigation, @test_result)
    else
      render "edit"
    end
  end

private

  def test_result_attributes
    params.require(:test_result).permit(:product_id, :legislation, :result, :details)
  end
end
