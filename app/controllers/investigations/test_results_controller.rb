class Investigations::TestResultsController < ApplicationController
  include FileConcern
  set_attachment_names :test_result_file
  set_file_params_key :test_result

  def new
    @investigation = investigation_from_params
    authorize @investigation, :update?
    @test_result = build_test_result_from_params
    attach_file_from_params
  end

  def create_draft
    @investigation = investigation_from_params
    authorize @investigation, :update?
    @test_result = build_test_result_from_params
    attach_file_from_params

    session[test_result_session_key] = @test_result.attributes
    update_attachment
    if test_result_valid?
      @file_blob.save! if @file_blob
      redirect_to confirm_investigation_test_results_path(@investigation)
    else
      render :new
    end
  end

  def confirm
    @investigation = investigation_from_params
    authorize @investigation, :update?
    @test_result = build_test_result_from_params
    attach_file_from_params
  end

  def create
    @investigation = investigation_from_params
    authorize @investigation, :update?
    @test_result = build_test_result_from_params
    attach_file_from_params

    update_attachment
    if test_result_saved?
      session[test_result_session_key] = nil
      initialize_file_attachments

      redirect_to investigation_supporting_information_index_path(@investigation),
                  flash: {
                    success: "#{@test_result.pretty_name.capitalize} was successfully recorded."
                  }
    else
      render :new
    end
  end

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

  def test_result_session_key
    "test_result_#{@investigation.id}"
  end

  def test_result_attributes
    params.require(:test_result).permit(:product_id, :legislation, :result, :details, date: %i[day month year])
  end

  def investigation_from_params
    Investigation.find_by!(pretty_id: params[:investigation_pretty_id])
      .decorate
  end

  def build_test_result_from_params
    @test_result_form = TestResultForm.new(test_params)
    test_result = @investigation.test_results.build(test_params)
    test_result.set_dates_from_params(params[:test_result])
    test_result
  end

  def test_params
    test_session_params.merge(test_result_request_params)
  end

  def test_result_request_params
    return {} if params[:test_result].blank?

    params.require(:test_result)
        .permit(:product_id,
                :legislation,
                :result,
                :details)
  end

  def attach_file_from_params
    @file_blob, * = load_file_attachments
    @test_result.documents.attach(@file_blob) if @file_blob
  end

  def update_attachment
    update_blob_metadata @file_blob, test_result_file_metadata
  end

  def test_result_file_metadata
    title = "#{@test_result.result&.capitalize} test: #{@test_result.product&.name}"
    document_type = "test_results"
    get_attachment_metadata_params(:file).merge(title: title, document_type: document_type)
  end

  def test_result_saved?
    test_result_valid? && @test_result.save
  end

  def test_result_valid?
    @test_result.validate
    validate_blob_size(@file_blob, @test_result.errors, "file")
    @test_result.errors.empty?
  end

  def test_session_params
    session[test_result_session_key] || {}
  end
end
