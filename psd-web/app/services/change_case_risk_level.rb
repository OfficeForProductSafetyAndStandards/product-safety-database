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
    send_notification_email
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
    AuditActivity::Investigation::RiskLevelUpdated.create_for!(
      investigation,
      action: change_action,
      source: UserSource.new(user: user)
    )
  end

  def entities_to_notify
    entities = []
    investigation.teams_with_access.each do |team|
      if team.team_recipient_email.present?
        entities << team
      else
        users_from_team = team.users.active
        entities.concat(users_from_team)
      end
    end
    entities.uniq - [context.user]
  end

  def send_notification_email
    entities_to_notify.each do |entity|
      email = entity.is_a?(Team) ? entity.team_recipient_email : entity.email
      NotifyMailer.case_risk_level_updated(
        email: email,
        name: entity.name,
        investigation: investigation,
        action: change_action,
        level: risk_level
      ).deliver_later
    end
  end
end
