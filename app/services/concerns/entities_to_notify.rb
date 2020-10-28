module EntitiesToNotify
  extend ActiveSupport::Concern

  def email_recipients_for_team_with_access
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

  # Notify the case owner, unless it is the same user/team performing the change
  def email_recipients_for_case_owner
    entities = [investigation.owner] - [user, user.team]

    entities.map { |entity|
      return entity.users.active if entity.is_a?(Team) && !entity.email

      entity
    }.flatten.uniq
  end
end
