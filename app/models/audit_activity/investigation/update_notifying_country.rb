class AuditActivity::Investigation::UpdateNotifyingCountry < AuditActivity::Investigation::Base
  def self.from(*)
    raise "Deprecated - use UpdateNotifyingCountry.call instead"
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

  def body
    "Notifying country changed from #{previous_country} to #{new_country}"
  end

private

  def previous_country
    metadata["updates"]["notifying_country"].first
  end

  def new_country
    metadata["updates"]["notifying_country"].second
  end

  # Do not send investigation_updated mail. This is handled by the ChangeRiskValidation service
  def notify_relevant_users; end
end
