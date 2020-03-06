require "notifications/client"

class SendUserInvitationJob < ApplicationJob
  GOV_UK_NOTIFY_TEMPLATE_ID = "22b3799c-aa3d-43e8-899d-3f30307a488f".freeze

  # If the user_inviting_id is present, it is implied that the invitation
  # is being sent (or resent) by a colleague, and so the invited_at time
  # is reset.
  #
  # If absent, it is implied that the user themselves requested a resend of the
  # invitation (eg by attempting to reset their password), and so the invited_at
  # time should not be altered, and a different email should be sent if the invitation
  # has already expired.
  def perform(user_id, user_inviting_id = nil)
    user = User.find(user_id)

    if user_inviting_id
      user_inviting = User.find(user_inviting_id)

      NotifyMailer.invitation_email(user, user_inviting).deliver_now
      user.update!(has_been_sent_welcome_email: true, invited_at: Time.current)

    elsif user.invitation_expired?
      NotifyMailer.expired_invitation_email(user).deliver_now
    else
      NotifyMailer.invitation_email(user, nil).deliver_now
    end
  end
end
