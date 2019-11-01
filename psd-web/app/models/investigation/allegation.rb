# coding: utf-8

class Investigation < ApplicationRecord
  class Allegation < Investigation
    validates :description, :hazard_type, :product_category, presence: true, on: :allegation_details
    validates :hazard_description, :hazard_type, presence: true, on: :unsafe
    validates :non_compliant_reason, presence: true, on: :non_compliant

    index_name [ENV.fetch("ES_NAMESPACE", "default_namespace"), Rails.env, "investigations"].join("_")

    def case_type
      "allegation"
    end

  private

    def create_audit_activity_for_case
      AuditActivity::Investigation::AddAllegation.from(self)
    end
  end
end
