class Investigation < ApplicationRecord
  class Enquiry < Investigation
    include DateConcern

    validates :user_title, :description, presence: true, on: :enquiry_details
    validates :date_received, presence: true, on: :about_enquiry, unless: :partially_filled_date?
    validate :date_cannot_be_in_the_future, on: :about_enquiry
    index_name [ENV.fetch("ES_NAMESPACE", "default_namespace"), Rails.env, "investigations"].join("_")

    date_attribute :date_received, required: false

    has_one :add_audit_activity,
            class_name: "AuditActivity::Investigation::AddEnquiry",
            foreign_key: :investigation_id,
            inverse_of: :investigation,
            dependent: :destroy

    def case_type
      "enquiry"
    end

    def partially_filled_date?
      errors.messages[:date_received_year].any? || errors.messages[:date_received_day].any? || errors.messages[:date_received_month].any?
    end

    def date_cannot_be_in_the_future
      if date_received.present? && date_received > Time.zone.today
        errors.add(:date_received, "Date received must be today or in the past")
      end
    end

    def create_audit_activity_for_case
      AuditActivity::Investigation::AddEnquiry.from(self)
    end
  end
end
