class Investigations::TestResultsController < ApplicationController
  include FileConcern
  set_attachment_names :file
  set_file_params_key :test

  before_action :set_investigation
  before_action :set_test, only: %i[new create_draft confirm create]
  before_action :set_attachment, only: %i[new create_draft confirm create]

  def new
    authorize @investigation, :update?
  end

  def create_draft
    authorize @investigation, :update?
    session[:test] = @test.attributes
    update_attachment
    if test_valid?
      @file_blob.save if @file_blob
      redirect_to confirm_investigation_test_results_path(@investigation)
    else
      render :new
    end
  end

  def confirm
    authorize @investigation, :update?
  end

  def create
    authorize @investigation, :update?
    update_attachment
    if test_saved?
      session[:test] = nil
      redirect_to investigation_supporting_information_index_path(@investigation),
                  flash: { success: "#{@test.pretty_name.capitalize} was successfully recorded." }
    else
      render :new
    end
  end

  def show
    authorize @investigation, :view_non_protected_details?
    @test_result = @investigation.test_results.find(params[:id]).decorate
  end

  def edit
    authorize @investigation, :update?
    @test_result = @investigation.test_results.find(params[:id])

    @file_blob = @test_result.documents.first.blob
  end

  def update
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

  def set_investigation
    @investigation = Investigation.find_by!(pretty_id: params[:investigation_pretty_id])
      .decorate
  end

  def set_test
    @test = @investigation.test_results.build(test_params)
    @test.set_dates_from_params(params[:test])
  end

  def test_params
    test_session_params.merge(test_request_params)
  end

  def test_request_params
    return {} if params[:test].blank?

    params.require(:test)
        .permit(:product_id,
                :legislation,
                :result,
                :details)
  end

  def set_attachment
    @file_blob, * = load_file_attachments
    @test.documents.attach(@file_blob) if @file_blob
  end

  def update_attachment
    update_blob_metadata @file_blob, test_file_metadata
  end

  def test_file_metadata
    title = "#{@test.result&.capitalize} test: #{@test.product&.name}"
    document_type = "test_results"
    get_attachment_metadata_params(:file).merge(title: title, document_type: document_type)
  end

  def test_saved?
    test_valid? && @test.save
  end

  def test_valid?
    @test.validate
    validate_blob_size(@file_blob, @test.errors, "file")
    @test.errors.empty?
  end

  def test_session_params
    session[:test] || {}
  end
end
