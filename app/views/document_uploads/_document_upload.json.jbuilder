json.extract! @document_upload, :id, :created_at, :updated_at
json.url document_upload_url(@document_upload, format: :json)
