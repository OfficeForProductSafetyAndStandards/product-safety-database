class AuditActivity::Investigation::UpdateCaseName < AuditActivity::Investigation::Base
  def self.build_metadata(investigation)
    updated_values = investigation.previous_changes.slice(:user_title)

    {
      updates: updated_values
    }
  end
end
