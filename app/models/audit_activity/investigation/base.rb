class AuditActivity::Investigation::Base < AuditActivity::Base
  def self.i18n_scope
    model_name.i18n_key.to_s.split("/")
  end

  private_class_method def self.from(investigation, title = nil, body = nil, metadata = nil)
    create!(
      source: UserSource.new(user: User.current),
      investigation: investigation,
      title: title,
      body: body,
      metadata: metadata
    )
  end
end
