class UpdateTestResult
  include Interactor
  include EntitiesToNotify

  delegate :test_result, :user, :new_attributes, :new_file, :new_file_description, :investigation, to: :context
  delegate :investigation, to: :test_result

  def call
    context.fail!(error: "No test result supplied") unless test_result.is_a?(Test::Result)
    context.fail!(error: "No new attributes supplied") unless new_attributes
    context.fail!(error: "No user supplied") unless user.is_a?(User)

    # These are all currently required to make sure that the validation is
    # triggered if the date fields are blank (otherwise existing date is used).
    #
    # TODO: refactor this by updating DateConcern.
    test_result.date = nil
    test_result.date_day = nil
    test_result.date_month = nil
    test_result.date_year = nil

    # Currently required by DateConcern
    test_result.set_dates_from_params(new_attributes)

    test_result.attributes = new_attributes.except(:date)

    blob = test_result.documents.first.blob
    context.previous_attachment_filename = blob.filename
    context.previous_attachment_description = blob.metadata[:description]

    test_result.transaction do
      replace_attached_file_with(new_file) if new_file

      break if no_changes?

      if test_result.save
        update_document_description
        create_audit_activity_for_test_result_updated
        send_notification_email
      else
        context.fail!
      end
    end
  end

private

  def replace_attached_file_with(new_file)
    test_result.documents.detach
    test_result.documents.attach(new_file)
  end

  def no_changes?
    !any_changes?
  end

  def any_changes?
    new_file || test_result.changes.except(:date_year, :date_month, :date_day).keys.any? || file_description_changed?
  end

  def file_description_changed?
    new_file_description != context.previous_attachment_description
  end

  def create_audit_activity_for_test_result_updated
    metadata = AuditActivity::Test::TestResultUpdated.build_metadata(test_result, context.previous_attachment_filename, context.previous_attachment_description)

    context.activity = AuditActivity::Test::TestResultUpdated.create!(
      source: UserSource.new(user: user),
      investigation: test_result.investigation,
      product: test_result.product,
      metadata: metadata,
      title: nil,
      body: nil,
      attachment: test_result.documents.first.blob
    )
  end

  # The document description is currently saved within the `metadata` JSON
  # on the 'blob' record. The TestResult model allows multiple
  # documents to be attached, but in practice the interfaces only allows one
  # at a time.
  def update_document_description
    document = test_result.documents.first
    document.blob.metadata[:description] = new_file_description
    document.blob.save!
  end

  def send_notification_email
    email_recipients_for_case_owner.each do |recipient|
      NotifyMailer.investigation_updated(
        test_result.investigation.pretty_id,
        recipient.name,
        recipient.email,
        "#{context.activity.source.show(recipient)} edited a test result on the #{test_result.investigation.case_type}.",
        "Test result edited for #{test_result.investigation.case_type.upcase_first}"
      ).deliver_later
    end
  end
end
