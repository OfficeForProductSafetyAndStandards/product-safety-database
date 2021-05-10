class AuditActivity::Investigation::UpdateVisibility < AuditActivity::Investigation::Base
  def self.from(_investigation)
    raise "Deprecated - use ChangeCaseVisibility.call instead"
  end

  def self.build_metadata(investigation, rationale)
    updated_values = investigation.previous_changes.slice(:is_private)

    {
      updates: updated_values,
      rationale: rationale
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

  # Do not send investigation_updated mail. This is handled by the ChangeCaseVisibility service
  def notify_relevant_users; end

  def already_in_new_format?
    self[:metadata]&.key?("updates")
  end
end
