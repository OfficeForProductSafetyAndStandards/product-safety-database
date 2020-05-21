class AuditActivity::Investigation::AddEnquiry < AuditActivity::Investigation::Add
  def self.from(investigation)
    super(investigation)
  end
end
