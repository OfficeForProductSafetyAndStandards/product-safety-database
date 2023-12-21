module EntitiesToNotify
  extend ActiveSupport::Concern

  def email_recipients_for_team_with_access(investigation, user_triggering_notifications)
    entities = []
    investigation.teams_with_access.each do |team|
      if team.team_recipient_email.present?
        entities << team
      else
        users_from_team = team.users.active
        entities.concat(users_from_team)
      end
    end
    entities.uniq - [user_triggering_notifications]
  end

  # Notify the case owner, unless it is the same user/team performing the change
  def email_recipients_for_case_owner(investigation)
    if investigation.owner_user && investigation.owner_user == user
      []
    elsif investigation.owner_user
      [investigation.owner_user]
    elsif investigation.owner_team && investigation.owner_team == user.team
      []
    elsif investigation.owner_team.email.present?
      [investigation.owner_team]
    else
      investigation.owner_team.users.active
    end
  end

  # Notify the case creator, unless it is the same user performing the change
  def email_recipients_for_case_creator
    return [] if investigation.creator_user && (investigation.creator_user == user)

    [investigation.creator_user]
  end

  def email_recipients_for_alerts
    User.active.map(&:email)
  end
end
