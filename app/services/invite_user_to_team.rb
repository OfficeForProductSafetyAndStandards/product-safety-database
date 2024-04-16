class InviteUserToTeam
  include Interactor

  delegate :user, :team, :inviting_user, :name, to: :context

  def call
    context.fail!(error: "No email or user supplied") unless email || user
    context.fail!(error: "No team supplied") unless team

    context.user ||= find_or_create_user

    send_invite
  end

private

  def find_or_create_user
    existing_user = User.find_by(email:)

    if existing_user&.deleted?
      reinstate_and_update_deleted_user(existing_user)
    elsif existing_user&.team == team
      existing_user
    else
      create_user
    end
  end

  def create_user
    User.create!(
      email:,
      organisation: team.organisation,
      skip_password_validation: true,
      team:,
      name:
    )
  end

  def reinstate_and_update_deleted_user(existing_user)
    existing_user.reset_to_invited_state!
    existing_user.update!(team:)
    existing_user
  end

  def send_invite
    if !user.invitation_token || (user.invited_at < 1.hour.ago)
      user.update! invitation_token: user.invitation_token || SecureRandom.hex(15), invited_at: Time.zone.now
    end

    Rails.logger.info "Invitation sent to user: #{user.id} by #{inviting_user&.id}"

    SendUserInvitationJob.perform_later(user.id, inviting_user&.id)
  end

  def email
    # User emails are forced to lower case when saved, so we must compare case insensitively
    context.email&.downcase
  end
end
