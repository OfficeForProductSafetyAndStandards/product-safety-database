class AuditActivity::Investigation::UpdateNotifyingCountryDecorator < ApplicationDecorator
  delegate_all

  def new_country
    metadata["updates"]["notifying_country"].last
  end

  def previous_country
    metadata["updates"]["notifying_country"].first
  end
end
