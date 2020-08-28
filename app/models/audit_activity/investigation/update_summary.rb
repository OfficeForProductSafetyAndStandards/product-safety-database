class AuditActivity::Investigation::UpdateSummary < AuditActivity::Investigation::Base
  def self.from(*)
    raise "Deprecated - use ChangeCaseSummary.call instead"
  end

  def self.build_metadata(investigation)
    updated_values = investigation.previous_changes.slice(:description)

    {
      updates: updated_values
    }
  end

  def title(_viewer)
    "#{investigation.case_type.upcase_first} summary updated"
  end

  def new_summary
    metadata["updates"]["description"].second
  end

private

  def subtitle_slug
    "Changed"
  end

  # Do not send investigation_updated mail. This is handled by the ChangeCaseSummary service
  def notify_relevant_users; end
end
