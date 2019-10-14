class Investigation::Project < Investigation
  include Indexable

  validates :user_title, :description, presence: true

  def self.model_name
    self.superclass.model_name
  end

  def title
    user_title
  end

  def case_type
    "project"
  end

private

  def create_audit_activity_for_case
    AuditActivity::Investigation::AddProject.from(self)
  end
end
