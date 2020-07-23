class UpdateCorrectiveAction
  include Interactor
  delegate :user, :corrective_action, :corrective_action_params, to: :context

  def call
    validate_inputs!
    clear_decided_date_to_trigger_date_validation
    store_previous_document
    fetch_new_file_params
    # byebug
    set_new_attributes_and_validate!

    corrective_action.transaction do
      # byebug
      if corrective_action.related_file_changed? && corrective_action.related_file?
        document = replace_attached_file_if_necessary(corrective_action, previous_document, new_file)
      elsif corrective_action.related_file_changed? && !corrective_action.related_file?
        corrective_action.documents.detach
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

  def old_document
    @old_document ||= corrective_action.documents.first
  end

  def new_file_description
    @new_file_description ||= new_file_params[:description]
  end

  def new_file
    @new_file ||= new_file_params[:file]
  end

  def new_file_params
    @new_file_params ||= corrective_action_params.delete(:file) || {}
  end
  alias_method :fetch_new_file_params, :new_file_params

  def validate_inputs!
    validate_corrective_action!
    validate_corrective_action_params!
    validate_user!
  end

  def validate_corrective_action!
    context.fail!(error: "No corractive action supplied") unless corrective_action.is_a?(CorrectiveAction)
  end

  def validate_corrective_action_params!
    context.fail!(error: "No corrective action params supplied") unless corrective_action_params
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

  def replace_attached_file_if_necessary(corrective_action, old_document, new_file)
    return old_document unless new_file

    corrective_action.documents.detach
    corrective_action.documents.attach(new_file).first
  end

  def clear_decided_date_to_trigger_date_validation
    corrective_action.date_decided = nil
    corrective_action.date_decided_day = nil
    corrective_action.date_decided_month = nil
    corrective_action.date_decided_year = nil
  end

  def set_new_attributes_and_validate!
    corrective_action.set_dates_from_params(corrective_action_params)
    corrective_action.assign_attributes(corrective_action_params.except(:date_decided))

    context.fail! if corrective_action.invalid?
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
