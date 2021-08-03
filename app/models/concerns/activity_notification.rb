# Legacy behaviour for those Activity subclasses which have not yet been
# refactored to use service classes. This should not be used anymore.
module ActivityNotification
  extend ActiveSupport::Concern

  included do
    after_save :notify_relevant_users
  end

  def email_update_text(viewer = nil); end

  def email_subject_text
    "#{investigation.case_type.upcase_first} updated"
  end

  def entities_to_notify
    entities = users_to_notify

    teams_to_notify.each do |team|
      if team.team_recipient_email.present?
        entities << team
      else
        users_from_team = team.users.active
        entities.concat(users_from_team)
      end
    end

    entities.uniq
  end

private

  def notify_relevant_users
    entities_to_notify.each do |entity|
      email = entity.is_a?(Team) ? entity.team_recipient_email : entity.email
      NotifyMailer.investigation_updated(investigation.pretty_id, entity.name, email, email_update_text(entity), email_subject_text).deliver_later
    end
  end

  def users_to_notify
    return [] unless investigation.owner.is_a? User
    return [] if source&.user == investigation.owner

    [investigation.owner]
  end

  def teams_to_notify
    return [] unless investigation.owner.is_a? Team
    return [] if source&.user&.team == investigation.owner

    [investigation.owner]
  end
end
