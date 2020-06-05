module TestsHelper
  def set_investigation
    investigation = Investigation.find_by!(pretty_id: params[:investigation_pretty_id])
    authorize investigation, :view_non_protected_details?
    @investigation = investigation.decorate
  end

  def set_test
    @test = @investigation.tests.build(test_params)
    @test.set_dates_from_params(params[:test])
  end

  def test_params
    test_session_params.merge(test_request_params)
  end

  def set_attachment
    @file_blob, * = load_file_attachments
    @test.documents.attach(@file_blob) if @file_blob
  end

  def update_attachment
    update_blob_metadata @file_blob, test_file_metadata
  end

  def test_valid?
    @test.validate
    validate_blob_size(@file_blob, @test.errors, "file")
    @test.errors.empty?
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def test_request_params
    return {} if params[:test].blank?

    params.require(:test)
        .permit(:product_id,
                :legislation,
                :result,
                :details)
        .merge(type: model_type)
  end

  def test_file_metadata
    if @test.requested?
      title = "Test requested: #{@test.product&.name}"
      document_type = "test_request"
    else
      title = "#{@test.result&.capitalize} test: #{@test.product&.name}"
      document_type = "test_results"
    end
    get_attachment_metadata_params(:file).merge(title: title, document_type: document_type)
  end

  def model_type
    params.dig(:test, :is_result) == "true" ? Test::Result.name : Test::Request.name
  end

  def test_result_summary_rows(test_result)
    rows = [
      {
        key: { text: "Date of test" },
        value: { text: test_result.date.to_s(:govuk) }
      },
      {
        key: { text: "Product tested" },
        value: { html: link_to(test_result.product.name, product_path(test_result.product)) }
      },
      {
        key: { text: "Legislation" },
        value: { text: test_result.legislation }
      },
      {
        key: { text: "Result" },
        value: { text: test_result.result.upcase_first }
      }
    ]

    if test_result.details.present?
      rows << {
        key: { text: "Further details" },
        value: { text: test_result.details }
      }
    end

    test_result.documents.each do |document|
      attachment_description = document.blob.metadata["description"]

      next if attachment_description.blank?

      rows << {
        key: { text: "Attachment description" },
        value: { text: attachment_description }
      }
    end

    rows
  end
end
