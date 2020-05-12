class Investigation < ApplicationRecord
  class Project < Investigation
    validates :user_title, :description, presence: true, on: :project_details

    index_name [ENV.fetch("ES_NAMESPACE", "default_namespace"), Rails.env, "investigations"].join("_")

    has_one :add_audit_activity,
            class_name: "AuditActivity::Investigation::AddProject",
            foreign_key: :investigation_id,
            inverse_of: :investigation,
            dependent: :destroy

    def case_type
      "project"
    end

    def create_audit_activity_for_case
      AuditActivity::Investigation::AddProject.from(self)
    end
  end
end
