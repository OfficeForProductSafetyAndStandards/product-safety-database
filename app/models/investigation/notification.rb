class Investigation < ApplicationRecord
  class Notification < Investigation
    include AASM

    has_one :add_audit_activity,
            class_name: "AuditActivity::Investigation::AddCase",
            foreign_key: :investigation_id,
            inverse_of: :investigation,
            dependent: :destroy

    aasm column: :state, whiny_transitions: false do
      state :draft, initial: true
      state :submitted

      event :submit do
        transitions from: :draft, to: :submitted
      end
    end

    def valid_api_dataset?
      user_title.present?
    end

    def case_type
      "notification"
    end

    def case_created_audit_activity_class
      AuditActivity::Investigation::AddCase
    end
  end
end
