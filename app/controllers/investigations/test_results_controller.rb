class Investigations::TestResultsController < Investigations::BaseController
  before_action :set_investigation
  before_action :authorize_investigation_updates, only: %i[new create edit update]
  before_action :set_investigation_breadcrumbs

  def new
    @test_result_form = TestResultForm.new
  end

  def create
    create_test_result_params = test_result_params
    create_test_result_params.merge!(session[:test_result_certificate]) if session[:test_result_certificate].present?

    @test_result_form = TestResultForm.new(create_test_result_params)
    @test_result_form.load_document_file

    return render :new if @test_result_form.invalid?(:create_with_investigation_product)

    service_attributes = @test_result_form
                           .serializable_hash
                           .merge(investigation: @investigation, user: current_user)

    result = AddTestResultToInvestigation.call(service_attributes)

    if result.success?
      ahoy.track "Added test result", { investigation_id: @investigation.id }
      return redirect_to investigation_supporting_information_index_path(@investigation), flash: { success: "The supporting information was updated" }
    end

    render :new
  end

  def show
    authorize @investigation, :view_non_protected_details?
    @test_result = @investigation.test_results.find(params[:id]).decorate
  end

  def edit
    @test_result_form = TestResultForm.from(@investigation.test_results.find(params[:id]))
    @test_result_form.load_document_file
  end

  def update
    test_result = @investigation.test_results.find(params[:id])

    @test_result_form = TestResultForm.from(test_result)
    @test_result_form.assign_attributes(test_result_params)
    @test_result_form.load_document_file

    if @test_result_form.invalid?(:create_with_investigation_product)
      @investigation = @investigation.decorate
      return render :edit
    end

    UpdateTestResult.call!(
      @test_result_form.serializable_hash
        .merge(test_result:,
               investigation: @investigation,
               user: current_user,
               changes: @test_result_form.changes)
    )

    ahoy.track "Updated test result", { investigation_id: @investigation.id }
    redirect_to investigation_supporting_information_index_path(@investigation), flash: { success: "The supporting information was updated" }
  end

private

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
