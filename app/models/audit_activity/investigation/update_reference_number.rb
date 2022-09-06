class AuditActivity::Investigation::UpdateReferenceNumber < AuditActivity::Investigation::Base
  def self.build_metadata(investigation)
    updated_values = investigation.previous_changes.slice(:complainant_reference)

    {
      updates: updated_values
    }
  end
end
