class AuditActivity::Investigation::Base < AuditActivity::Base
  private_class_method def self.from(investigation, title = nil, body = nil, metadata = nil)
    create(
      source: UserSource.new(user: User.current),
      investigation: investigation,
      title: title,
      body: body,
      metadata: metadata
    )
  end
end
