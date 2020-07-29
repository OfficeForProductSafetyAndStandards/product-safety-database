class UpdateCorrectiveAction
  include Interactor
  delegate :user, :corrective_action, :previous_documents, :file_description, to: :context

  def call
    validate_inputs!

    corrective_action.transaction do

      if corrective_action.related_file_changed? && !corrective_action.related_file?
        corrective_action.documents.detach
      elsif corrective_action.related_file_changed?
        document = replace_attached_file_if_necessary(corrective_action, previous_document, new_file)
      end

      corrective_action.save!

      document_changed = (document != previous_document)
      document_changed_description_changed = update_document_description!(document, new_file_description) if document

      return unless any_changes?(document_changed, document_changed_description_changed)

      send_notification_email(create_audit_activity_for_corrective_action_update!(previous_document))
    end
  end

private

  def any_changes?(document_changed, document_changed_description_changed)
    corrective_action_changes? || document_changed || document_changed_description_changed
  end

  def previous_document
    @previous_document ||= corrective_action.documents.first
  end
  alias_method :store_previous_document, :previous_document

  def update_document_description!(document, new_file_description)
    document_changed_description_changed = (document.blob.metadata[:description] != new_file_description)
    document.blob.metadata[:description] = new_file_description
    document.blob.save!

    document_changed_description_changed
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
