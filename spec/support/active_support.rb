module ActiveSupportHelper
module_function

  def create_file(_model, evaluator, content_type: "text/plain", metadata: {})
    ActiveStorage::Blob.create_and_upload!(
      io: File.open(evaluator.document_file),
      filename: File.basename(evaluator.document_file),
      content_type:,
      metadata:
    )
  end
end
