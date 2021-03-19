class AuditActivity::Investigation::ChangeNotifyingCountry < AuditActivity::Investigation::Base
  def self.from(*)
    raise "Deprecated - use ChangeNotifyingCountry.call instead"
  end

  def self.build_metadata(investigation)
    updated_values = investigation.previous_changes.slice(:notifying_country)

    {
      updates: updated_values
    }
  end

  def title(*)
    "Notifying country changed"
  end

  def previous_country
    metadata["updates"]["notifying_country"].first
  end

  def new_country
    metadata["updates"]["notifying_country"].second
  end

private

  # Do not send investigation_updated mail. This is handled by the ChangeNotifyingCountry service
  def notify_relevant_users; end
end
