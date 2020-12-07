class ChangeRiskValidation
  include Interactor
  include EntitiesToNotify

  delegate :investigation, :is_risk_validated, :user, to: :context

  def call
    context.fail!(error: "No investigation supplied") unless investigation.is_a?(Investigation)
    context.fail!(error: "No risk validation supplied") if is_risk_validated.nil?
    context.fail!(error: "No user supplied") unless user.is_a?(User)

    context.changes_made = false

    investigation.assign_attributes(is_risk_validated: is_risk_validated)
    return if investigation.changes.none?

    ActiveRecord::Base.transaction do
      investigation.save!
      create_audit_activity_for_risk_validation_changed
    end

    context.changes_made = true
  end

private

  def create_audit_activity_for_risk_validation_changed
    metadata = activity_class.build_metadata(investigation)

    activity_class.create!(
      source: UserSource.new(user: user),
      investigation: investigation,
      title: nil,
      body: nil,
      metadata: metadata
    )
  end

  def activity_class
    AuditActivity::Investigation::UpdateCoronavirusStatus
  end
end
