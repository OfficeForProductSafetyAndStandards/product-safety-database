class NotifyTeamAddedToCaseJob < ApplicationJob
  def perform(collaborator)
    team = collaborator.collaborating

    if team.team_recipient_email.present?
      NotifyMailer.team_added_to_case_email(collaborator, to_email: team.team_recipient_email).deliver_later
    else
      team.users.active.each do |user|
        NotifyMailer.team_added_to_case_email(collaborator, to_email: user.email).deliver_later
      end
    end
  end
end
