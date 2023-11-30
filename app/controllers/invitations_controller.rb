class InvitationsController < ApplicationController
  def new
    @team = find_team_and_authorize_invite
    @invite_user_to_team_form = InviteUserToTeamForm.new
  end

  def create
    @team = find_team_and_authorize_invite
    @invite_user_to_team_form = InviteUserToTeamForm.new(form_params)

    return render :new, status: :bad_request unless @invite_user_to_team_form.valid?

    invitation = InviteUserToTeam.call(form_params.merge({ inviting_user: current_user }))

    redirect_to @team, flash: { success: t("invite_user_to_team.invite_sent", email: invitation.user.email) }
  end

  def resend
    team = find_team_and_authorize_invite
    user = team.users.find(params[:id])

    invitation = InviteUserToTeam.call({ user:, team:, inviting_user: current_user })

    redirect_to(team, flash: { success: t("invite_user_to_team.invite_sent", email: invitation.user.email) })
  rescue ActiveRecord::RecordNotFound
    render "errors/not_found", status: :not_found
  end

private

  def find_team_and_authorize_invite
    team = Team.find(params[:team_id])
    authorize team, :invite_or_remove_user?
    team
  end

  # See: SecondaryAuthenticationConcern
  def current_operation
    SecondaryAuthentication::INVITE_USER
  end

  def form_params
    params.require(:invite_user_to_team_form).permit(:email, :name).merge({ team: @team })
  end
end
