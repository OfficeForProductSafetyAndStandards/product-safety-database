class AuditActivity::Investigation::Base < AuditActivity::Base
  def self.i18n_scope
    model_name.i18n_key.to_s.split("/")
  end
end
