class UpdateCorrectiveAction
  include Interactor
  delegate :user, :corrective_action, :corrective_action_params, to: :context

  def call
    context.fail!(error: "No corractive action supplied") unless corrective_action.is_a?(CorrectiveAction)
    context.fail!(error: "No corrective action params supplied") unless corrective_action_params
    context.fail!(error: "No user supplied") unless user.is_a?(User)

    corrective_action.date_decided = nil
    corrective_action.date_decided_day = nil
    corrective_action.date_decided_month = nil
    corrective_action.date_decided_year = nil

    new_file_params      = corrective_action_params.delete(:file)
    new_file             = new_file_params[:file]
    new_file_description = new_file_params[:description]

    corrective_action.set_dates_from_params(corrective_action_params)
    corrective_action.assign_attributes(corrective_action_params.except(:date_decided))

    old_document = corrective_action.documents.first

    if corrective_action.invalid?
      context.fail!
    end

    corrective_action.transaction do
      corrective_action_changes = corrective_action.changes.any?
      corrective_action.save!

      document = replace_attached_file_if_necessary(corrective_action, old_document, new_file)

      document_changed = (document != old_document)
      document_changed_description_changed = (document.blob.metadata[:description] != new_file_description)

      document.blob.metadata[:description] = new_file_description
      document.blob.save!

      return unless corrective_action_changes || document_changed || document_changed_description_changed

      create_audit_activity_for_corrective_action_update
    end
  end

private

  def create_audit_activity_for_corrective_action_update
    metadata = AuditActivity::CorrectiveAction::Update.build_metadata(corrective_action)

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

    old_document.purge
    corrective_action.documents.attach(new_file).first
  end
end
