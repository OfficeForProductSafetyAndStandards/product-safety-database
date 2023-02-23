class AuditActivity::Document::Add < AuditActivity::Document::Base
  has_one_attached :attachment

  def self.build_metadata(blob)
    blob.metadata.merge(blob_id: blob.id)
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
end
