class Investigation < ApplicationRecord
  class Project < Investigation
    validates :user_title, :description, presence: true, on: :project_details

    has_one :add_audit_activity,
            class_name: "AuditActivity::Investigation::AddProject",
            foreign_key: :investigation_id,
            inverse_of: :investigation,
            dependent: :destroy

    def case_type
      "project"
    end

    def case_created_audit_activity_class
      AuditActivity::Investigation::AddProject
    end
  end
end
