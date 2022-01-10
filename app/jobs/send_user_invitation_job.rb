require "notifications/client"

class SendUserInvitationJob < ApplicationJob
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

    return NotifyMailer.expired_invitation_email(user).deliver_now if user.invitation_expired?

    user_inviting = user_inviting_id ? User.find(user_inviting_id) : nil

    NotifyMailer.invitation_email(user, user_inviting).deliver_now

    user.update!(has_been_sent_welcome_email: true)
  end
end
