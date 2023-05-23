class ChangeCaseRiskLevel
  include Interactor
  include EntitiesToNotify

  AUDIT_ACTIVITY_CLASS = AuditActivity::Investigation::RiskLevelUpdated

  delegate :investigation, :risk_level, :user, :change_action, :updated_risk_level, to: :context

  def call
    context.fail!(error: "No investigation supplied") unless investigation.is_a?(Investigation)
    context.fail!(error: "No user supplied") unless user.is_a?(User)

    context.risk_level = nil unless Investigation.risk_levels.key?(context.risk_level)

    investigation.assign_attributes(risk_level: risk_level.presence)

    context.change_action = Investigation::RiskLevelChange.new(investigation).change_action
    return unless change_action

    ActiveRecord::Base.transaction do
      investigation.save!
      create_audit_activity_for_risk_level_update
    end

    context.updated_risk_level = investigation.decorate.risk_level_description
    send_notification_email(investigation, user)
  end

private

  def create_audit_activity_for_risk_level_update
    AUDIT_ACTIVITY_CLASS.create!(
      added_by_user: user,
      investigation:,
      metadata: AUDIT_ACTIVITY_CLASS.build_metadata(investigation, change_action)
    )
  end

  def send_notification_email(investigation, user)
    return unless investigation.sends_notifications?

    email_recipients_for_team_with_access(investigation, user).each do |entity|
      email = entity.is_a?(Team) ? entity.team_recipient_email : entity.email
      NotifyMailer.case_risk_level_updated(
        email:,
        name: entity.name,
        investigation:,
        update_verb: change_action.to_s,
        level: updated_risk_level
      ).deliver_later
    end
  end
end
