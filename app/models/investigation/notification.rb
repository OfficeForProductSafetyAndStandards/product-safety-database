class Investigation < ApplicationRecord
  class Notification < Investigation
    include AASM

    TASK_LIST_SECTIONS = {
      "product" => %i[search_for_or_add_a_product],
      "notification_details" => %i[add_notification_details add_product_safety_and_compliance_details add_product_identification_details],
      "business_details" => %i[search_for_or_add_a_business add_business_details add_business_location add_business_contact],
      "evidence" => %i[add_test_reports add_supporting_images add_supporting_documents add_risk_assessments determine_notification_risk_level],
      "corrective_actions" => %i[record_a_corrective_action],
      "submit" => %i[check_notification_details_and_submit]
    }.freeze

    TASK_LIST_SECTIONS_OPTIONAL = %w[evidence].freeze

    # Each hidden task is the key to a hash, the value of which is the task whose completion
    # should unlock the hidden task in question.
    TASK_LIST_TASKS_HIDDEN = [
      { add_business_details: :add_product_identification_details },
      { add_business_location: :add_product_identification_details },
      { add_business_contact: :add_product_identification_details }
    ].freeze

    has_one :add_audit_activity,
            class_name: "AuditActivity::Investigation::AddCase",
            foreign_key: :investigation_id,
            inverse_of: :investigation,
            dependent: :destroy

    aasm column: :state, whiny_transitions: false do
      state :draft, initial: true
      state :submitted

      event :submit do
        transitions from: :draft, to: :submitted, guard: :ready_to_submit?
      end
    end

    def all_products_have_affected_units?
      investigation_products.map { |investigation_product| investigation_product.affected_units_status.present? }.all?(true)
    end

    def ready_to_submit?
      # Ensure all mandatory sections have been completed *and* every product has a value for "number of units affected"
      draft? &&
        TASK_LIST_SECTIONS.except(*TASK_LIST_SECTIONS_OPTIONAL, "submit").values.flatten.excluding(*TASK_LIST_TASKS_HIDDEN.map(&:keys).flatten).map { |task| tasks_status[task.to_s] == "completed" }.all?(true) &&
        all_products_have_affected_units?
    end

    def case_type
      "notification"
    end

    def case_created_audit_activity_class
      AuditActivity::Investigation::AddCase
    end
  end
end
