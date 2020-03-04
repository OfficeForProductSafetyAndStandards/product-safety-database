module ActiveSupportHelper
  def create_file(_model, evaluator, metadata: {})
    ActiveStorage::Blob.create_after_upload!(
      io: File.open(evaluator.document_file),
      filename: File.basename(evaluator.document_file),
      content_type: "text/plain",
      metadata: metadata
    )
  end
  module_function :create_file
end
