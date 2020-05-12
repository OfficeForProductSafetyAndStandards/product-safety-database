# coding: utf-8

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

    def create_audit_activity_for_case
      AuditActivity::Investigation::AddAllegation.from(self)
    end
  end
end
