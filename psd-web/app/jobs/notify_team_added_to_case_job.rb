class NotifyTeamAddedToCaseJob < ApplicationJob
  def perform(collaboration)
    collaborator = collaboration.collaborator

    if collaborator.team_recipient_email.present?
      NotifyMailer.team_added_to_case_email(collaboration, to_email: collaborator.team_recipient_email).deliver_later
    else
      collaborator.users.active.each do |user|
        NotifyMailer.team_added_to_case_email(collaboration, to_email: user.email).deliver_later
      end
    end
  end
end
