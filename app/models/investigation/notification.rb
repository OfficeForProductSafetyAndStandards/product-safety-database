class Investigation < ApplicationRecord
  class Notification < Investigation
    include AASM

    TASK_LIST_SECTIONS = {
      "product" => %i[search_for_or_add_a_product],
      "notification_details" => %i[add_notification_details add_product_safety_and_compliance_details add_number_of_affected_units],
      "business_details" => %i[search_for_or_add_a_business add_business_details add_business_location add_business_contact confirm_business_details add_business_roles],
      "evidence" => %i[add_product_identification_details add_test_reports add_supporting_images add_supporting_documents add_risk_assessments determine_notification_risk_level],
      "corrective_actions" => %i[record_a_corrective_action],
      "submit" => %i[check_notification_details_and_submit]
    }.freeze

    TASK_LIST_SECTIONS_OPTIONAL = %w[evidence].freeze

    # Each hidden task is the key to a hash, the value of which is the task whose completion
    # should unlock the hidden task in question.
    TASK_LIST_TASKS_HIDDEN = [
      { add_business_details: :add_number_of_affected_units },
      { add_business_location: :add_number_of_affected_units },
      { add_business_contact: :add_number_of_affected_units },
      { add_business_roles: :add_number_of_affected_units },
      { confirm_business_details: :add_number_of_affected_units },
    ].freeze

    DRAFT_NOTIFICATION_AGE_LIMIT = 90.days

    scope :old_drafts, -> { where(state: "draft").where("updated_at < ?", DRAFT_NOTIFICATION_AGE_LIMIT.ago) }

    has_one :add_audit_activity,
            class_name: "AuditActivity::Investigation::AddCase",
            foreign_key: :investigation_id,
            inverse_of: :investigation,
            dependent: :destroy

    has_many :comments,
             class_name: "AuditActivity::Investigation::AddComment",
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

    def valid_api_dataset?
      user_title.present?
    end

    def ready_to_submit?
      # Ensure all mandatory sections have been completed
      draft? &&
        TASK_LIST_SECTIONS.except(*TASK_LIST_SECTIONS_OPTIONAL, "submit").values.flatten.excluding(*TASK_LIST_TASKS_HIDDEN.map(&:keys).flatten).map { |task| tasks_status[task.to_s] == "completed" }.all?(true)
    end

    def case_type
      "notification"
    end

    def case_created_audit_activity_class
      AuditActivity::Investigation::AddCase
    end

    def self.hard_delete_old_drafts!
      Rails.logger.info "Starting to hard delete old draft notifications"
      processed_count = 0

      old_drafts.find_each do |notification|
        notification.destroy!
        processed_count += 1
      rescue StandardError => e
        Rails.logger.error "Failed to hard delete notification #{notification.id}: #{e.message}"
      end

      Rails.logger.info "Completed hard deleting old draft notifications. Processed: #{processed_count}"
    end

    def virus_free_images
      image_uploads.select { |image_upload| image_upload&.file_upload&.safe? }
    end
  end
end
