class AuditActivity::Investigation::UpdateStatus < AuditActivity::Investigation::Base
  def self.from(_investigation)
    raise "Deprecated - use ChangeCaseStatus.call instead"
  end

  def self.build_metadata(investigation, rationale)
    updated_values = investigation.previous_changes.slice(:is_closed, :date_closed)

    {
      updates: updated_values,
      rationale: rationale
    }
  end

private

  # Do not send investigation_updated mail. This is handled by the ChangeCaseStatus service
  def notify_relevant_users; end
end
