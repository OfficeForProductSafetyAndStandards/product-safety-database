class Investigation < ApplicationRecord
  class Case < Investigation
    index_name [ENV.fetch("OS_NAMESPACE", "default_namespace"), Rails.env, "investigations"].join("_")

    has_one :add_audit_activity,
            class_name: "AuditActivity::Investigation::AddCase",
            foreign_key: :investigation_id,
            inverse_of: :investigation,
            dependent: :destroy

    def case_created_audit_activity_class
      AuditActivity::Investigation::AddCase
    end
  end
end
