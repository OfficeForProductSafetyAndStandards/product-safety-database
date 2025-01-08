class AuditActivity::Document::Add < AuditActivity::Document::Base
  has_one_attached :attachment

  def self.build_metadata(blob)
    blob.metadata.merge(blob_id: blob.id)
  end

  def metadata
    migrate_metadata_structure
  end

  def title(_user)
    metadata["title"]
  end

  def description
    metadata["description"]
  end

  def restricted_title(_user)
    "Document added"
  end

private

  def migrate_metadata_structure
    metadata = self[:metadata]

    return metadata if metadata

    new_metadata = self.class.build_metadata(attachment.blob)
    new_metadata["title"] = self[:title]
    new_metadata["description"] = self[:body]

    JSON.parse(new_metadata.to_json)
  end

  def subtitle_slug
    "#{attachment_type} added"
  end
end
