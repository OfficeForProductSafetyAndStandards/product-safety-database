class ChangeCaseRiskLevel
  include Interactor

  delegate :investigation, :risk_level, :user, :change_action, to: :context

  def call
    context.fail!(error: "No investigation supplied") unless investigation.is_a?(Investigation)
    context.fail!(error: "No user supplied") unless user.is_a?(User)

    context.change_action = risk_level_change_action
    return unless change_action

    ActiveRecord::Base.transaction do
      investigation.risk_level = risk_level.presence
      investigation.save!
      create_audit_activity_for_risk_level_update
    end
  end

private

  def risk_level_change_action
    if investigation.risk_level.to_s == risk_level.to_s
      nil
    elsif investigation.risk_level.blank?
      "set"
    elsif risk_level.blank?
      "removed"
    else
      "changed"
    end
  end

  def create_audit_activity_for_risk_level_update
    AuditActivity::Investigation::UpdateRiskLevel.from(
      investigation,
      action: change_action,
      source: UserSource.new(user: user)
    )
  end
end
