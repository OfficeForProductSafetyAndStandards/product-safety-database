class Investigations::TestsController < ApplicationController
  include FileConcern
  set_attachment_names :file
  set_file_params_key :test

  before_action :set_investigation
  before_action :set_test
  before_action :set_attachment

  def new
    set_test
    authorize @investigation, :update?
    render :details
  end

  def create_draft
    authorize @investigation, :update?
    store_test
    update_attachment
    if test_valid?
      save_attachment
      redirect_to confirm_investigation_tests_path(@investigation)
    else
      render :details
    end
  end

  def confirm
    authorize @investigation, :update?
    render :confirmation
  end

  def create
    authorize @investigation, :update?
    update_attachment
    if test_saved?
      redirect_to investigation_supporting_information_index_path(@investigation),
                  flash: { success: "#{@test.pretty_name.capitalize} was successfully recorded." }
    else
      render :details
    end
  end

private

  def set_investigation
    investigation = Investigation.find_by!(pretty_id: params[:investigation_pretty_id])
    authorize investigation, :view_non_protected_details?
    @investigation = investigation.decorate
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

  def clear_session
    session[:test] = nil
    initialize_file_attachments
  end

  def store_test
    session[:test] = @test.attributes
  end

  def test_saved?
    return false unless test_valid?

    @test.save
  end

  def test_valid?
    @test.validate
    validate_blob_size(@file_blob, @test.errors, "file")
    @test.errors.empty?
  end

  def save_attachment
    @file_blob.save if @file_blob
  end

  def test_session_params
    session[:test] || {}
  end
end
