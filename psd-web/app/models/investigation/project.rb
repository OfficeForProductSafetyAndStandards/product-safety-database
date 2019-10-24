class Investigation::Project < Investigation

  validates :user_title, :description, presence: true

  index_name [ENV.fetch("ES_NAMESPACE", "default_namespace"), Rails.env, 'investigations'].join("_")

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
