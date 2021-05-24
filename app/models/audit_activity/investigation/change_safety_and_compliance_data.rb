class AuditActivity::Investigation::ChangeSafetyAndComplianceData < AuditActivity::Investigation::Base
  def self.build_metadata(investigation)
    updated_values = investigation.previous_changes.slice(:hazard_type, :hazard_description, :non_compliant_reason, :reported_reason)

    {
      updates: updated_values
    }
  end

  def title(*)
    "Safety and compliance status changed"
  end
end
