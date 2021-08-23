class AuditActivity::Document::Destroy < AuditActivity::Document::Base
  has_one_attached :attachment

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

    JSON.parse(self.class.build_metadata(attachment.blob).to_json)
  end

  def subtitle_slug
    "#{attachment_type} deleted"
  end
end
