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
    @test_result_form.load_document_file

    @investigation = investigation.decorate
    return render :new if @test_result_form.invalid?(:create_with_product)

    service_attributes = @test_result_form
                           .serializable_hash
                           .merge(investigation: investigation, user: current_user)

    result = AddTestResultToInvestigation.call(service_attributes)

    if result.success?
      flash_message = "#{result.test_result.pretty_name.capitalize} was successfully recorded."
      return redirect_to investigation_supporting_information_index_path(investigation), flash: { success: flash_message }
    end

    @investigation = investigation.decorate
    render :new
  end

  def show
    investigation = Investigation.find_by!(pretty_id: params[:investigation_pretty_id])
    authorize investigation, :view_non_protected_details?
    @test_result = investigation.test_results.find(params[:id]).decorate
    @investigation = investigation.decorate
  end

  def edit
    investigation = Investigation.find_by!(pretty_id: params[:investigation_pretty_id])
    authorize investigation, :update?
    @test_result_form = TestResultForm.from(investigation.test_results.find(params[:id]))
    @test_result_form.load_document_file
    @investigation = investigation.decorate
  end

  def update
    investigation = Investigation.find_by!(pretty_id: params[:investigation_pretty_id])
    authorize investigation, :update?

    test_result = investigation.test_results.find(params[:id])

    @test_result_form = TestResultForm.from(test_result)
    @test_result_form.assign_attributes(test_result_params)
    @test_result_form.load_document_file

    if @test_result_form.invalid?(:create_with_product)
      @investigation = investigation.decorate
      return render :edit
    end

    result = UpdateTestResult.call(
      @test_result_form.serializable_hash
        .merge(test_result: test_result,
               investigation: investigation,
               user: current_user,
               changes: @test_result_form.changes)
    )

    return redirect_to investigation_test_result_path(investigation, test_result) if result.success?

    @investigation = investigation.decorate
    render "edit"
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
      :failure_details,
      :standards_product_was_tested_against,
      :existing_document_file_id,
      :test_result_file,
      date: %i[day month year],
      document_form: %i[description file]
    )
  end
end
