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

    corrective_action.set_dates_from_params(corrective_action_params)
    corrective_action.assign_attributes(corrective_action_params.except(:date_decided))

    if corrective_action.invalid?
      context.fail!(error: corrective_action.errors.full_messages.to_sentence)
    end

    corrective_action.save!
    create_audit_activity_for_corrective_action_update
  end

private

  def create_audit_activity_for_corrective_action_update
    metadata = AuditActivity::CorrectiveAction::Update.build_metadata(corrective_action)

    context.activity = AuditActivity::CorrectiveAction::Update.create!(
      source: UserSource.new(user: user),
      investigation: corrective_action.investigation,
      product: corrective_action.product,
      business: corrective_action.business,
      metadata: metadata,
      title: nil,
      body: nil,
    )
  end
end
