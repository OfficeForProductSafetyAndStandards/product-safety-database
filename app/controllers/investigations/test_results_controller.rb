class Investigations::TestResultsController < ApplicationController
  before_action :set_investigation
  before_action :authorize_investigation_update, only: %i[new create edit update]

  def new
    @test_result_form = TestResultForm.new
  end

  def create
    @test_result_form = TestResultForm.new(test_result_params)
    @test_result_form.load_document_file

    return render :new if @test_result_form.invalid?(:create_with_investigation_product)

    service_attributes = @test_result_form
                           .serializable_hash
                           .merge(investigation: @investigation_object, user: current_user)

    result = AddTestResultToInvestigation.call(service_attributes)

    if result.success?
      return redirect_to investigation_supporting_information_index_path(@investigation_object), flash: { success: "The supporting information was updated" }
    end

    render :new
  end

  def show
    authorize @investigation_object, :view_non_protected_details?
    @test_result = @investigation_object.test_results.find(params[:id]).decorate
  end

  def edit
    @test_result_form = TestResultForm.from(@investigation_object.test_results.find(params[:id]))
    @test_result_form.load_document_file
  end

  def update
    test_result = @investigation_object.test_results.find(params[:id])

    @test_result_form = TestResultForm.from(test_result)
    @test_result_form.assign_attributes(test_result_params)
    @test_result_form.load_document_file

    if @test_result_form.invalid?(:create_with_investigation_product)
      @investigation = @investigation_object.decorate
      return render :edit
    end

    UpdateTestResult.call!(
      @test_result_form.serializable_hash
        .merge(test_result:,
               investigation: @investigation_object,
               user: current_user,
               changes: @test_result_form.changes)
    )

    redirect_to investigation_supporting_information_index_path(@investigation_object), flash: { success: "The supporting information was updated" }
  end

private

  def set_investigation
    @investigation_object = Investigation.find_by!(pretty_id: params[:investigation_pretty_id])
    @investigation = @investigation_object.decorate
  end

  def authorize_investigation_update
    authorize @investigation_object, :update?
  end

  def test_params
    test_session_params.merge(test_result_request_params)
  end

  def test_result_params
    params.require(:test_result).permit(
      :details,
      :legislation,
      :investigation_product_id,
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
