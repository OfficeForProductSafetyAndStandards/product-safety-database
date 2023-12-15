class UpdateCorrectiveAction
  include Interactor
  include EntitiesToNotify

  delegate :investigation, to: :corrective_action
  delegate :user, :corrective_action, :action, :business_id, :date_decided, :details, :duration, :geographic_scopes, :online_recall_information, :has_online_recall_information, :legislation, :measure_type, :other_action, :investigation_product_id, :related_file, :document, :file_description, :changes, to: :context

  def call
    validate_inputs!
    assign_attributes
    @previous_attachment = corrective_action.document_blob
    corrective_action.transaction do
      corrective_action.document.detach unless related_file
      replace_attached_file             if file_changed?

      context.document = corrective_action.document if user_has_attached_file?

      if any_changes?
        corrective_action.save!
        update_document_description!
        create_audit_activity_for_corrective_action_updated!
        send_notification_email

        investigation.reindex
      end
    end
  end

private

  def assign_attributes
    corrective_action.assign_attributes(
      action:,
      business_id:,
      date_decided:,
      details:,
      duration:,
      geographic_scopes:,
      online_recall_information:,
      has_online_recall_information:,
      legislation:,
      measure_type:,
      other_action:,
      investigation_product_id:
    )
  end

  def any_changes?
    file_changed? || changes.except(:related_file, :existing_document_file_id, :document).any?
  end

  def file_changed?
    return false if document.nil? && related_file
    return false if document == @previous_attachment

    document.try(:checksum) != @previous_attachment.try(:checksum)
  end

  def replace_attached_file
    corrective_action.document.detach
    corrective_action.document.attach(document)
  end

  # The document description is currently saved within the `metadata` JSON
  # on the 'blob' record. The CorrectiveAction model allows multiple
  # documents to be attached, but in practice the interfaces only allows one
  # at a time.
  def update_document_description!
    return unless document

    document.metadata[:description] = file_description
    document.save!
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

  def user_has_attached_file?
    related_file && document
  end

  def create_audit_activity_for_corrective_action_updated!
    metadata = AuditActivity::CorrectiveAction::Update.build_metadata(corrective_action, changes)

    AuditActivity::CorrectiveAction::Update.create!(
      added_by_user: user,
      investigation:,
      investigation_product: corrective_action.investigation_product,
      business: corrective_action.business,
      metadata:,
      title: nil,
      body: nil,
    )
  end

  def send_notification_email
    return unless investigation.sends_notifications?

    email_recipients_for_case_owner.each do |recipient|
      NotifyMailer.investigation_updated(
        investigation.pretty_id,
        recipient.name,
        recipient.email,
        "#{user.decorate.display_name(viewer: recipient)} edited a corrective action on the notification.",
        "Corrective action edited for notification"
      ).deliver_later
    end
  end
end
