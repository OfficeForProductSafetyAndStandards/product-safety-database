class AuditActivity::Document::Update < AuditActivity::Document::Base
  has_one_attached :attachment

  def self.build_metadata(blob)
    {
      blob_id: blob.id,
      updates: blob.previous_changes.slice(:metadata)
    }
  end

  def title(_user)
    if title_changed?
      "Updated: #{new_title || 'Untitled document'} (was: #{old_title || 'Untitled document'})"
    elsif description_changed?
      "Updated: Description for #{new_title}"
    end
  end

  def new_description
    metadata["updates"]["metadata"].last["description"]
  end

  def restricted_title(_user)
    "Document updated"
  end

end
