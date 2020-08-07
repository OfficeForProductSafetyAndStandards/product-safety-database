class UpdateCorrectiveAction
  include Interactor
  delegate :user, :corrective_action, :corrective_action_params, to: :context
  delegate :investigation, to: :corrective_action
  def call
    validate_inputs!
    assign_attributes
    set_dates_from_params
    @previous_attachment = corrective_action.documents.first
    corrective_action.transaction do
      corrective_action.documents.detach unless corrective_action.related_file
      replace_attached_file              if new_file
      context.fail!                      if corrective_action.invalid?
      break                              if no_changes?

      corrective_action.save!

      update_document_description!

      actvity = create_audit_activity_for_corrective_action_updated!(@previous_attachment)

      send_notification_email(actvity)
    end
  end

private

  def assign_attributes
    corrective_action.assign_attributes(corrective_action_params.except(:file, :date_decided))
  end

  def set_dates_from_params
    corrective_action.set_dates_from_params(corrective_action_params)
  end

  def no_changes?
    !any_changes?
  end

  def any_changes?
    file_changed? || corrective_action.changes.except(:date_decided_year, :date_decided_month, :date_decided_day, :related_file).any? || file_description_changed?
  end

  def file_changed?
    [new_file, @previous_attachment].compact.any?
  end

  def new_file
    corrective_action_params.dig(:file, :file)
  end

  def new_file_description
    description = corrective_action_params.dig(:file, :description)
    return nil if description.blank?

    description
  end

  def file_description_changed?
    old_file_description = @previous_attachment&.metadata&.dig(:description)
    return false if new_file_description.blank? && old_file_description.blank?

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
  def update_document_description!
    document = corrective_action.documents.first

    return unless document

    document.blob.metadata[:description] = new_file_description
    document.blob.save!
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

  def create_audit_activity_for_corrective_action_updated!(previous_document)
    metadata = AuditActivity::CorrectiveAction::Update.build_metadata(corrective_action, previous_document)

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

  def send_notification_email(activity)
    entities_to_notify.each do |recipient|
      NotifyMailer.investigation_updated(
        investigation.pretty_id,
        recipient.name,
        recipient.email,
        "#{activity.source.show(recipient)} edited a corrective action on the #{investigation.case_type}.",
        "Corrective action edited for #{investigation.case_type.upcase_first}"
      ).deliver_later
    end
  end

  def entities_to_notify
    return [] if user == investigation.owner_user
    return [investigation.owner_user, investigation.owner_team] if investigation.owner_team.email?

    User
      .active
      .where(team_id: investigation.teams_with_access.map(&:id))
      .where.not(id: user.id)
  end
end
