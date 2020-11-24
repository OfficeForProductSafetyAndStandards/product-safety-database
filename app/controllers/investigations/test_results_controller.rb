class Investigations::TestResultsController < ApplicationController
  def new
    investigation = Investigation.find_by(pretty_id: params[:investigation_pretty_id])
    authorize investigation, :update?
    @test_result_form = TestResultForm.new
    @investigation = investigation.decorate
  end

  def create
    investigation = Investigation.find_by(pretty_id: params[:investigation_pretty_id])
    authorize investigation, :update?
    @test_result_form = TestResultForm.new(test_result_params)
    @test_result_form.cache_file!
    @test_result_form.load_document_file

    return render :new if @test_result_form.invalid?

    result = AddTestResultToInvestigation.call(@test_result_form.serializable_hash.merge(investigation: investigation, user: current_user))

    if result.success?
      redirect_to investigation_test_result_path(investigation, result.test_result)
    else
      @investigation = investigation.decorate
      render :new
    end
  end

  # def create
  #   @investigation = investigation_from_params
  #   authorize @investigation, :update?
  #   @test_result = build_test_result_from_params
  #   attach_file_from_params

  #   update_attachment
  #   if test_result_saved?
  #     session[test_result_session_key] = nil
  #     initialize_file_attachments

  #     redirect_to investigation_supporting_information_index_path(@investigation),
  #                 flash: {
  #                   success: "#{@test_result.pretty_name.capitalize} was successfully recorded."
  #                 }
  #   else
  #     render :new
  #   end
  # end

  def show
    @investigation = investigation_from_params
    authorize @investigation, :view_non_protected_details?
    @test_result = @investigation.test_results.find(params[:id]).decorate
  end

  def edit
    @investigation = investigation_from_params
    authorize @investigation, :update?
    @test_result = @investigation.test_results.find(params[:id])
    @file_blob = @test_result.documents.first.blob
  end

  def update
    @investigation = investigation_from_params
    authorize @investigation, :update?

    @test_result = @investigation.test_results.find(params[:id])

    result = UpdateTestResult.call(
      test_result: @test_result,
      new_attributes: test_result_attributes,
      new_file: params[:test_result][:test_result_file][:file],
      new_file_description: params[:test_result][:test_result_file][:description],
      user: current_user
    )

    if result.success?
      redirect_to investigation_test_result_path(@investigation, @test_result)
    else
      render "edit"
    end
  end

private

  def test_params
    test_session_params.merge(test_result_request_params)
  end

  def test_result_params
    params.require(:test_result).permit(
      :details,
      :legislation,
      :product_id,
      :result,
      :standard_product_was_tested_against,
      :test_result_file,
      date: %i[day month year],
      document: [:description, file: []]
    )
  end
end
