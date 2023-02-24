class AuditActivity::Document::Update < AuditActivity::Document::Base
  has_one_attached :attachment

  def self.build_metadata(blob)
    {
      blob_id: blob.id,
      updates: blob.previous_changes.slice(:metadata)
    }
  end

  def metadata
    migrate_metadata_structure
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

private

  def migrate_metadata_structure
    metadata = self[:metadata]

    return metadata if metadata

    title_matches = self[:title].match(/\AUpdated: (.*) \(was: (.*)\)\z/)
    new_title = title_matches&.captures&.first
    old_title = title_matches&.captures&.last

    # We can't reconstruct the old description for comparison so we will need to compare the new description with nil
    description_changed = self[:title].start_with?("Updated: Description for")

    new_metadata = {
      blob_id: attachment.blob.id,
      updates: {
        metadata: [
          {
            title: old_title,
            description: nil
          },
          {
            title: new_title,
            description: (description_changed ? self[:body] : nil)
          }
        ]
      }
    }

    JSON.parse(new_metadata.to_json)
  end

  def subtitle_slug
    "#{attachment_type} details updated"
  end

  def title_changed?
    old_title != new_title
  end

  def description_changed?
    old_description != new_description
  end

  def old_title
    metadata["updates"]["metadata"].first["title"]
  end

  def new_title
    metadata["updates"]["metadata"].last["title"]
  end

  def old_description
    metadata["updates"]["metadata"].first["description"]
  end
end
