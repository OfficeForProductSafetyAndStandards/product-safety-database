class AuditActivity::Investigation::AddAllegation < AuditActivity::Investigation::Add
  def self.from(investigation)
    super(investigation)
  end
end
