require 'notifications/client'

class SendUserInvitationJob < ApplicationJob
  GOV_UK_NOTIFY_TEMPLATE_ID = "22b3799c-aa3d-43e8-899d-3f30307a488f"

  def perform(user_id)
    user = User.find(user_id)
    NotifyMailer.invitation_email(email: user.email).deliver_now
    user.update(has_been_sent_welcome_email: true)
  end
end
