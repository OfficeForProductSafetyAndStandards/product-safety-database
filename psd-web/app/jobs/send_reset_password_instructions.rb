class SendResetPasswordInstructions < ApplicationJob
  def perform(user, token)
    NotifyMailer.reset_password_instruction(user, token).deliver_now
  end
end
