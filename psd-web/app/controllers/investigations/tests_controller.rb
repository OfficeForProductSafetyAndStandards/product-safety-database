class Investigations::TestsController < ApplicationController
  include FileConcern
  set_attachment_names :file
  set_file_params_key :test

  include Wicked::Wizard
  steps :details, :confirmation

  before_action :set_investigation
  before_action :set_test, only: %i[show create update]
  before_action :set_attachment, only: %i[show create update]
  before_action :store_test, only: %i[update]

  # GET /tests/1
  def show
    authorize @investigation, :update?
    render_wizard
  end

  # GET /tests/new_result
  def new_result
    clear_session
    redirect_to wizard_path(steps.first, request.query_parameters)
  end

  # POST /tests
  def create
    authorize @investigation, :update?
    update_attachment
    if test_saved?
      redirect_to investigation_supporting_information_index_path(@investigation),
                  flash: { success: "#{@test.pretty_name.capitalize} was successfully recorded." }
    else
      render step
    end
  end

  # PATCH/PUT /tests/1
  def update
    authorize @investigation, :update?
    update_attachment
    if test_valid?
      save_attachment
      redirect_to next_wizard_path
    else
      render step
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
