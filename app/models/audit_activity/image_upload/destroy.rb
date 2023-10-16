class AuditActivity::ImageUpload::Destroy < AuditActivity::ImageUpload::Base
  has_one_attached :file_upload

  def self.build_metadata(blob)
    blob.metadata.merge(blob_id: blob.id, blob_filename: blob.filename)
  end

  def metadata
    migrate_metadata_structure
  end

  def title(_user)
    "Deleted: #{metadata['blob_filename']}"
  end

  def restricted_title(_user)
    "Image deleted"
  end

private

  def migrate_metadata_structure
    metadata = self[:metadata]

    return metadata if metadata

    JSON.parse(self.class.build_metadata(attachment.blob).to_json)
  end

  def subtitle_slug
    "Image deleted"
  end
end
