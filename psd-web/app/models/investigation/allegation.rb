class Investigation < ApplicationRecord
  class Allegation < Investigation
    validates :description, :hazard_type, :product_category, presence: true, on: :allegation_details

    index_name [ENV.fetch("ES_NAMESPACE", "default_namespace"), Rails.env, "investigations"].join("_")

    has_one :add_audit_activity,
            class_name: "AuditActivity::Investigation::AddAllegation",
            foreign_key: :investigation_id,
            inverse_of: :investigation,
            dependent: :destroy

    def case_type
      "allegation"
    end

    def case_created_audit_activity_class
      AuditActivity::Investigation::AddAllegation
    end
  end
end
