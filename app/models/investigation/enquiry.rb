class Investigation < ApplicationRecord
  class Enquiry < Investigation
    validates :description, :user_title, presence: true, on: :enquiry_details
    validates :date_received,
              presence: true,
              real_date: true,
              complete_date: true,
              not_in_future: true,
              on: :about_enquiry

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
