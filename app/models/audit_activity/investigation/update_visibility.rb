class AuditActivity::Investigation::UpdateVisibility < AuditActivity::Investigation::Base
  def self.build_metadata(investigation, rationale)
    updated_values = investigation.previous_changes.slice(:is_private)

    {
      updates: updated_values,
      rationale:
    }
  end

end
