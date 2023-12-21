class AuditActivity::Investigation::UpdateStatus < AuditActivity::Investigation::Base
  def self.build_metadata(notification, rationale)
    updated_values = notification.previous_changes.slice(:is_closed, :date_closed)

    {
      updates: updated_values,
      rationale:
    }
  end
end
