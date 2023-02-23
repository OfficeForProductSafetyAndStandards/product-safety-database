class AuditActivity::Document::Destroy < AuditActivity::Document::Base
  has_one_attached :attachment

  def self.build_metadata(blob)
    blob.metadata.merge(blob_id: blob.id)
  end

  def title(_user)
    "Deleted: #{metadata['title']}"
  end

  def restricted_title(_user)
    "Document deleted"
  end

end
