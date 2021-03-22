class AuditActivity::Investigation::ChangeSafetyAndComplianceData < AuditActivity::Investigation::Base
  def self.from(*)
    raise "Deprecated - use ChangeSafetyAndComplianceData.call instead"
  end

  def self.build_metadata(investigation)
    updated_values = investigation.previous_changes.slice(:hazard_type, :hazard_description, :non_compliant_reason, :reported_reason)

    {
      updates: updated_values
    }
  end

  def title(*)
    "#{investigation.case_type.upcase_first} changed"
  end

private

  # Do not send investigation_updated mail. This is handled by the ChangeSafetyAndComplianceData service
  def notify_relevant_users; end
end
