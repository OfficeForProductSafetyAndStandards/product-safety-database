class Investigation < ApplicationRecord
  class Allegation < Investigation
    validates :description, :product_category, :hazard_type, presence: true, on: :allegation_details

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
