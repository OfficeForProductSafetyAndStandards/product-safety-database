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

    result = UpdateTestResult.call(
      test_result: @test_result,
      new_attributes: test_result_attributes,
      new_file: params[:test_result][:file][:file],
      new_file_description: params[:test_result][:file][:description],
      user: current_user
    )

    if result.success?
      redirect_to investigation_test_result_path(@investigation, @test_result)
    else
      render "edit"
    end
  end

private

  def test_result_attributes
    params.require(:test_result).permit(:product_id, :legislation, :result, :details, date: %i[day month year])
  end
end
