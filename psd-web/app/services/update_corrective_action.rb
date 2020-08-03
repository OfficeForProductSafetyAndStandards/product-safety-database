class UpdateCorrectiveAction
  include Interactor
  delegate :user, :corrective_action, :corrective_action_params, to: :context

  def call
    validate_inputs!

    corrective_action.date_decided = nil
    corrective_action.date_decided_day = nil
    corrective_action.date_decided_month = nil
    corrective_action.date_decided_year = nil
    corrective_action.assign_attributes(corrective_action_params.except(:file, :date_decided))
    corrective_action.set_dates_from_params(corrective_action_params)

    @previous_attachment = corrective_action.documents.first

    context.fail! if corrective_action.invalid?

    new_file = corrective_action_params.dig("file", "file")

    corrective_action.transaction do
      corrective_action.documents.detach unless corrective_action.related_file
      replace_attached_file if new_file

      break if no_changes?

      corrective_action.save!
      update_document_description
      actvity = create_audit_activity_for_corrective_action_updated(@previous_attachment)

      send_notification_email(actvity)
    end
  end

private

  def no_changes?
    !any_changes?
  end

  def any_changes?
    new_file || corrective_action.changes.except(:date_year, :date_month, :date_day).keys.any? || file_description_changed?
  end

  def new_file
    corrective_action_params.dig(:file, :file)
  end

  def new_file_description
    corrective_action_params.dig(:file, :description)
  end

  def file_description_changed?
    new_file_description != @previous_attachment&.metadata&.dig(:description)
  end

  def replace_attached_file
    corrective_action.documents.detach
    corrective_action.documents.attach(new_file)
  end

  # The document description is currently saved within the `metadata` JSON
  # on the 'blob' record. The CorrectiveAction model allows multiple
  # documents to be attached, but in practice the interfaces only allows one
  # at a time.
  def update_document_description
    document = corrective_action.documents.first

    return unless document

    document.blob.metadata[:description] = new_file_description
    document.blob.save
  end

  def validate_inputs!
    validate_corrective_action!
    validate_user!
  end

  def validate_corrective_action!
    context.fail!(error: "No corractive action supplied") unless corrective_action.is_a?(CorrectiveAction)
  end

  def validate_user!
    context.fail!(error: "No user supplied") unless user.is_a?(User)
  end

  def create_audit_activity_for_corrective_action_updated(previous_document)
    metadata = AuditActivity::CorrectiveAction::Update.build_metadata(corrective_action, previous_document)

    AuditActivity::CorrectiveAction::Update.create!(
      source: UserSource.new(user: user),
      investigation: corrective_action.investigation,
      product: corrective_action.product,
      business: corrective_action.business,
      metadata: metadata,
      title: nil,
      body: nil,
    )
  end

  def create_audit_activity_for_corrective_action_update!(old_document)
    metadata = AuditActivity::CorrectiveAction::Update.build_metadata(corrective_action, old_document)

    AuditActivity::CorrectiveAction::Update.create!(
      source: UserSource.new(user: user),
      investigation: corrective_action.investigation,
      product: corrective_action.product,
      business: corrective_action.business,
      metadata: metadata,
      title: nil,
      body: nil,
    )
  end

  def investigation
    corrective_action.investigation
  end

  def send_notification_email(activity)
    activity.entities_to_notify.each do |recipient|
      email = recipient.is_a?(Team) ? recipient.team_recipient_email : recipient.email

      NotifyMailer.investigation_updated(
        corrective_action.investigation.pretty_id,
        recipient.name,
        email,
        "#{activity.source.show(recipient)} edited a corrective action on the #{investigation.case_type}.",
        "Corrective action edited for #{corrective_action.investigation.case_type.upcase_first}"
      ).deliver_later
    end
  end

  def corrective_action_changes?
    corrective_action.previous_changes.except(:date_decided_day, :date_decided_month, :date_decided_year).any?
  end
end
