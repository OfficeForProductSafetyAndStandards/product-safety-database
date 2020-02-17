require "notifications/client"

class SendUserInvitationJob < ApplicationJob
  include Rails.application.routes.url_helpers
  GOV_UK_NOTIFY_TEMPLATE_ID = "22b3799c-aa3d-43e8-899d-3f30307a488f".freeze

  def perform(user_id, user_inviting_id)
    user = User.find(user_id)
    user_inviting = User.find(user_inviting_id)

    invitation_url = create_account_user_url(user.id, invitation: user.invitation_token, host: ENV.fetch("PSD_HOST"))

    NotifyMailer.invitation_email(user.email, invitation_url, user_inviting.name).deliver_now
    user.update(has_been_sent_welcome_email: true)
  end
end
