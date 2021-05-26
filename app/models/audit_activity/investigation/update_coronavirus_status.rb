class AuditActivity::Investigation::UpdateCoronavirusStatus < AuditActivity::Investigation::Base
  def self.build_metadata(investigation)
    updated_values = investigation.previous_changes.slice(:coronavirus_related)

    {
      updates: updated_values
    }
  end

  def title(*)
    I18n.t(".title.#{new_status}", scope: self.class.i18n_scope)
  end

  def body
    I18n.t(".body.#{new_status}", scope: self.class.i18n_scope)
  end

  def new_status
    metadata["updates"]["coronavirus_related"].second
  end
end
