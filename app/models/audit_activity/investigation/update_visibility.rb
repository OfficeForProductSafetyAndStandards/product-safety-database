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

private

  # Do not send investigation_updated mail. This is handled by the ChangeCaseVisibility service
  def notify_relevant_users; end
end
