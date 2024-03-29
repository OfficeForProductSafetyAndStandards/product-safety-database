class UpdateTestResult
  include Interactor
  include EntitiesToNotify

  delegate :user, :investigation, :test_result, :document, :date, :details, :legislation,
           :result, :standards_product_was_tested_against, :investigation_product_id,
           :failure_details, :tso_certificate_reference_number, :tso_certificate_issue_date,
           :changes, to: :context

  def call
    context.fail!(error: "No test result supplied")   unless test_result.is_a?(Test::Result)
    context.fail!(error: "No investigation supplied") unless investigation.is_a?(Investigation)
    context.fail!(error: "No user supplied")          unless user.is_a?(User)

    test_result.transaction do
      if tso_certificate_reference_number.present? || tso_certificate_issue_date.present?
        test_result.assign_attributes(
          tso_certificate_reference_number:,
          tso_certificate_issue_date:,
        )
      else
        test_result.assign_attributes(
          date:,
          details:,
          legislation:,
          result:,
          failure_details: updated_failure_details,
          standards_product_was_tested_against:,
          investigation_product_id:,
        )

        test_result.document.detach
        test_result.document.attach(document)
      end

      if test_result.save
        create_audit_activity_for_test_result_updated if any_changes?
        send_notification_email unless context.silent
      else
        context.fail!
      end
    end
  end

private

  def create_audit_activity_for_test_result_updated
    metadata = AuditActivity::Test::TestResultUpdated.build_metadata(test_result, changes)

    context.activity = AuditActivity::Test::TestResultUpdated.create!(
      added_by_user: user,
      investigation: test_result.investigation,
      investigation_product: test_result.investigation_product,
      metadata:
    )
  end

  def send_notification_email
    return unless test_result.investigation.sends_notifications?

    email_recipients_for_case_owner(investigation).each do |recipient|
      NotifyMailer.notification_updated(
        test_result.investigation.pretty_id,
        recipient.name,
        recipient.email,
        "#{user.decorate.display_name(viewer: recipient)} edited a test result on the notification.",
        "Test result edited for notification"
      ).deliver_later
    end
  end

  def updated_failure_details
    return if result == "passed"

    failure_details
  end

  def file_replaced_with_same_file?
    if changes["document"] && changes["document"].first.present?
      checksums = changes["document"].map(&:checksum)
      checksums.first == checksums.second
    end
  end

  def any_changes?
    changes = self.changes
    if file_replaced_with_same_file?
      changes = changes.except(:document, :existing_document_file_id)
    end
    changes.any?
  end
end
