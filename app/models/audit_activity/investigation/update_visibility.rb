class AuditActivity::Investigation::UpdateVisibility < AuditActivity::Investigation::Base
  def self.build_metadata(investigation, rationale)
    updated_values = investigation.previous_changes.slice(:is_private)

    {
      updates: updated_values,
      rationale:
    }
  end

  def metadata
    migrate_metadata_structure
  end

private

  def migrate_metadata_structure
    metadata = self[:metadata]

    return metadata if already_in_new_format?

    { "updates" => { "is_private" => [nil, title.match?(/\s+restricted$/im)] } }
  end

  def already_in_new_format?
    self[:metadata]&.key?("updates")
  end
end
