class AuditActivity::DocumentUpload::Destroy < AuditActivity::DocumentUpload::Base
  has_one_attached :file_upload

  def self.build_metadata(blob)
    blob.metadata.merge(blob_id: blob.id)
  end

  def metadata
    migrate_metadata_structure
  end

  def title(_user)
    "Deleted: #{metadata['title']}"
  end

  def restricted_title(_user)
    "Document deleted"
  end

private

  def migrate_metadata_structure
    metadata = self[:metadata]

    return metadata if metadata

    JSON.parse(self.class.build_metadata(file_upload.blob).to_json)
  end

  def subtitle_slug
    "#{attachment_type} deleted"
  end
end
