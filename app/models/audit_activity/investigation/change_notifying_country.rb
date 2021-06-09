class AuditActivity::Investigation::ChangeNotifyingCountry < AuditActivity::Investigation::Base
  def self.build_metadata(investigation)
    updated_values = investigation.previous_changes.slice(:notifying_country)

    {
      updates: updated_values
    }
  end

  def title(*)
    "Notifying country changed"
  end

  def body
    "Notifying country changed from #{previous_country} to #{new_country}"
  end

  def previous_country
    metadata["updates"]["notifying_country"].first
  end

  def new_country
    metadata["updates"]["notifying_country"].second
  end
end
