class UpdateTestResult
  include Interactor

  delegate :test_result, :user, :new_attributes, :new_file, :new_file_description, to: :context

  def call
    context.fail!(error: "No rest result supplied") unless test_result.is_a?(Test::Result)
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

    ActiveRecord::Base.transaction do
      if new_file
        # remove previous attachment
        test_result.documents.first&.purge_later

        test_result.documents.attach(new_file)
      end

      if any_changes?
        if test_result.save

          update_document_description

          create_audit_activity_for_test_result_updated

        else
          context.fail!
        end
      end
    end
  end

private

  def any_changes?
    !test_result.changes.except(:date_year, :date_month, :date_day).keys.empty?
  end

  def create_audit_activity_for_test_result_updated
    metadata = AuditActivity::Test::TestResultUpdated.build_metadata(test_result)

    AuditActivity::Test::TestResultUpdated.create!(
      source: UserSource.new(user: user),
      investigation: test_result.investigation,
      product: test_result.product,
      metadata: metadata,
      title: nil,
      body: nil
    )
  end

  # The document description is currently saved within the `metadata` JSON
  # on the 'blob' record. The TestResult model allows multiple
  # documents to be attached, but in practice the interfaces only allows one
  # at a time.
  def update_document_description
    document = test_result.documents.first
    document.blob.metadata[:description] = new_file_description
    document.blob.save
  end
end
