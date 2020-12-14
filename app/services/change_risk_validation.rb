class ChangeRiskValidation
  include Interactor
  include EntitiesToNotify

  delegate :investigation, :risk_validated_at, :risk_validated_by, :is_risk_validated, :risk_validation_change_rationale, :user, to: :context

  def call
    # we need risk_validation_change_rationale
    context.fail!(error: "No investigation supplied") unless investigation.is_a?(Investigation)
    context.fail!(error: "No user supplied") unless user.is_a?(User)

    context.changes_made = false

    assign_risk_validation_attributes
    return if investigation.changes.none?

    ActiveRecord::Base.transaction do
      investigation.save!
      create_audit_activity_for_risk_validation_changed
    end

    context.changes_made = true

    investigation
  end

private

  def create_audit_activity_for_risk_validation_changed
    # we need risk_validation_change_rationale
    metadata = activity_class.build_metadata(investigation, risk_validation_change_rationale)

    activity_class.create!(
      source: UserSource.new(user: user),
      investigation: investigation,
      title: nil,
      body: nil,
      metadata: metadata
    )
  end

  def activity_class
    AuditActivity::Investigation::UpdateRiskLevelValidation
  end

  def assign_risk_validation_attributes
    if is_risk_validated
      investigation.assign_attributes(risk_validated_at: risk_validated_at, risk_validated_by: risk_validated_by)
    else
      investigation.assign_attributes(risk_validated_at: nil, risk_validated_by: nil)
    end
  end
end
