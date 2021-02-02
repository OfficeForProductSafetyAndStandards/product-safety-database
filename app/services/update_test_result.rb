class UpdateTestResult
  include Interactor
  include EntitiesToNotify

  delegate :test_result, :user, :investigation, :document, :date, :details, :legislation, :result, :standards_product_was_tested_against, :product_id, :changes, to: :context

  def call
    context.fail!(error: "No test result supplied")   unless test_result.is_a?(Test::Result)
    context.fail!(error: "No investigation supplied") unless investigation.is_a?(Investigation)
    context.fail!(error: "No user supplied")          unless user.is_a?(User)

    test_result.assign_attributes(
      date: date,
      details: details,
      legislation: legislation,
      result: result,
      standards_product_was_tested_against: standards_product_was_tested_against,
      product_id: product_id,
    )

    test_result.transaction do
      test_result.document.detach
      test_result.document.attach(document)

      if test_result.save
        create_audit_activity_for_test_result_updated if changes.any?
        send_notification_email
      else
        context.fail!
      end
    end
  end

private

  def create_audit_activity_for_test_result_updated
    metadata = AuditActivity::Test::TestResultUpdated.build_metadata(test_result, changes)

    context.activity = AuditActivity::Test::TestResultUpdated.create!(
      source: UserSource.new(user: user),
      investigation: test_result.investigation,
      product: test_result.product,
      metadata: metadata
    )
  end

  def send_notification_email
    email_recipients_for_case_owner.each do |recipient|
      NotifyMailer.investigation_updated(
        test_result.investigation.pretty_id,
        recipient.name,
        recipient.email,
        "#{UserSource.new(user: user).show(recipient)} edited a test result on the #{test_result.investigation.case_type}.",
        "Test result edited for #{test_result.investigation.case_type.upcase_first}"
      ).deliver_later
    end
  end
end
