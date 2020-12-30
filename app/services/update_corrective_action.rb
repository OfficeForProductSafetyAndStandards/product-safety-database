class UpdateCorrectiveAction
  include Interactor
  include EntitiesToNotify

  delegate :investigation, to: :corrective_action
  delegate :user, :corrective_action, :action, :business_id, :date_decided, :details, :duration, :geographic_scope, :has_online_recall_information, :legislation, :measure_type, :other_action, :product_id, :related_file, :document, :file_description, :changes, to: :context

  def call
    validate_inputs!
    assign_attributes
    @previous_attachment = corrective_action.document_blob
    corrective_action.transaction do
      corrective_action.document.detach unless related_file
      replace_attached_file             if file_changed?
      break                             if no_changes?

      corrective_action.save!
      update_document_description!
      create_audit_activity_for_corrective_action_updated!
      send_notification_email

      # trigger re-index of to for the model to pick up children relationships saved after the model
      investigation.reload.__elasticsearch__.index_document
    end
  end

private

  def assign_attributes
    corrective_action.assign_attributes(
      action: action,
      business_id: business_id,
      date_decided: date_decided,
      details: details,
      duration: duration,
      geographic_scope: geographic_scope,
      has_online_recall_information: has_online_recall_information,
      legislation: legislation,
      measure_type: measure_type,
      other_action: other_action,
      product_id: product_id
    )
  end

  def no_changes?
    !any_changes?
  end

  def any_changes?
    file_changed? || changes.except(:related_file).any?
  end

  def file_changed?
    return false if document.nil? && related_file
    return false if document == @previous_attachment

    [document, @previous_attachment].compact.any?
  end

  def new_file_description
    return nil if file_description.blank?

    file_description
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

    document.metadata[:description] = new_file_description
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

  def create_audit_activity_for_corrective_action_updated!
    metadata = AuditActivity::CorrectiveAction::Update.build_metadata(corrective_action, changes)

    AuditActivity::CorrectiveAction::Update.create!(
      source: UserSource.new(user: user),
      investigation: investigation,
      product: corrective_action.product,
      business: corrective_action.business,
      metadata: metadata,
      title: nil,
      body: nil,
    )
  end

  def send_notification_email
    email_recipients_for_case_owner.each do |recipient|
      NotifyMailer.investigation_updated(
        investigation.pretty_id,
        recipient.name,
        recipient.email,
        "#{user.decorate.display_name(viewer: recipient)} edited a corrective action on the #{investigation.case_type}.",
        "Corrective action edited for #{investigation.case_type.upcase_first}"
      ).deliver_later
    end
  end
end
