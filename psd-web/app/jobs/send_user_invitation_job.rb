require 'notifications/client'

class SendUserInvitationJob < ApplicationJob
  GOV_UK_NOTIFY_TEMPLATE_ID = "22b3799c-aa3d-43e8-899d-3f30307a488f"

  def perform(user_id)
    user = User.find(user_id)
    client = Notifications::Client.new(ENV.fetch('NOTIFY_API_KEY'))
    client.send_email(
      email_address: user.email,
      template_id: GOV_UK_NOTIFY_TEMPLATE_ID,
    )
  end
end