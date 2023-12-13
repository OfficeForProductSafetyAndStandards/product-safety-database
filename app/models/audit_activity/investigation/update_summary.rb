class AuditActivity::Investigation::UpdateSummary < AuditActivity::Investigation::Base
  def self.build_metadata(investigation)
    updated_values = investigation.previous_changes.slice(:description)

    {
      updates: updated_values
    }
  end

  def title(_viewer)
    "Notification summary updated"
  end

  def new_summary
    metadata["updates"]["description"].second
  end

private

  def subtitle_slug
    "Changed"
  end
end
