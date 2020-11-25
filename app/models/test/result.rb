class Test::Result < Test

  enum result: { passed: "Pass", failed: "Fail", other: "Other" }

  def create_audit_activity
    AuditActivity::Test::Result.from(self)
  end

  def pretty_name
    "test result"
  end

  def requested?
    false
  end
end
