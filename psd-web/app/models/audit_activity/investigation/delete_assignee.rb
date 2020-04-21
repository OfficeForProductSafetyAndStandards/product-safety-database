class AuditActivity::Investigation::DeleteAssignee < AuditActivity::Investigation::Base
  def self.from(investigation)
    super(investigation, title(investigation), nil)
  end

  def self.title(investigation)
    "User #{investigation.assignee.display_name} deleted"
  end

  def entities_to_notify
    []
  end
end
