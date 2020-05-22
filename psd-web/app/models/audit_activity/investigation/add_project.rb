class AuditActivity::Investigation::AddProject < AuditActivity::Investigation::Add
  def self.from(investigation)
    super(investigation)
  end
end
