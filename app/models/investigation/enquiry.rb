class Investigation < ApplicationRecord
  class Enquiry < Investigation
    validates :user_title, :description, presence: true, on: :enquiry_details
    validates :date_received,
              presence: true,
              real_date: true,
              complete_date: true,
              not_in_future: true,
              on: :about_enquiry

    index_name [ENV.fetch("ES_NAMESPACE", "default_namespace"), Rails.env, "investigations"].join("_")

    attribute :date_received, :govuk_date

    has_one :add_audit_activity,
            class_name: "AuditActivity::Investigation::AddEnquiry",
            foreign_key: :investigation_id,
            inverse_of: :investigation,
            dependent: :destroy

    def case_type
      "enquiry"
    end

    def case_created_audit_activity_class
      AuditActivity::Investigation::AddEnquiry
    end
  end
end
