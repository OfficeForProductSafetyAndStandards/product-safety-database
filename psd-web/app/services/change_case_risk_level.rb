class ChangeCaseRiskLevel
  include Interactor

  delegate :investigation, :risk_level, :custom_risk_level, :user, :change_action, :updated_risk_level, to: :context

  def call
    context.fail!(error: "No investigation supplied") unless investigation.is_a?(Investigation)
    context.fail!(error: "No user supplied") unless user.is_a?(User)

    context.risk_level = nil unless Investigation.risk_levels.key?(context.risk_level)

    investigation.assign_attributes(risk_level: risk_level.presence, custom_risk_level: custom_risk_level.presence)

    risk_level_change = Investigation::RiskLevelChange.new(investigation)
    context.change_action = risk_level_change.change_action
    return unless change_action

    ActiveRecord::Base.transaction do
      investigation.save!
      create_audit_activity_for_risk_level_update
    end

    context.updated_risk_level = investigation.decorate.risk_level_description
    send_notification_email
  end

private

  def create_audit_activity_for_risk_level_update
    AuditActivity::Investigation::RiskLevelUpdated.create_for!(
      investigation,
      update_verb: change_action,
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
        update_verb: change_action.to_s,
        level: updated_risk_level
      ).deliver_later
    end
  end
end
