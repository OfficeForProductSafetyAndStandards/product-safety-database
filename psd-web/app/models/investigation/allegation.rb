# coding: utf-8

class Investigation < ApplicationRecord
  class Allegation < Investigation
    validates :description, :hazard_type, :product_category, presence: true, on: :allegation_details

    validates :hazard_description, :hazard_type, presence: true, on: :why_reporting, if: :reported_unsafe?
    validates :non_compliant_reason, presence: true, on: :why_reporting, if: :reported_non_compliant?

    index_name [ENV.fetch("ES_NAMESPACE", "default_namespace"), Rails.env, "investigations"].join("_")

    has_one :add_audit_activity,
            class_name: "AuditActivity::Investigation::AddAllegation",
            foreign_key: :investigation_id,
            inverse_of: :investigation,
            dependent: :destroy

    def case_type
      "allegation"
    end

  private

    def reported_unsafe?
      reported_reason == :unsafe || reported_reason == :unsafe_and_non_compliant
    end

    def reported_non_compliant?
      reported_reason == :non_compliant || reported_reason == :unsafe_and_non_compliant
    end

    def create_audit_activity_for_case
      AuditActivity::Investigation::AddAllegation.from(self)
    end
  end
end
