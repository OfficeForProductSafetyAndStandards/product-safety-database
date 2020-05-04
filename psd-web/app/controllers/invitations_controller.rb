class InvitationsController < ApplicationController
  before_action :get_team
  before_action :authorize_team_invite

  def new
    @invite_user_to_team_form = InviteUserToTeamForm.new
  end

  def create
    @invite_user_to_team_form = InviteUserToTeamForm.new(form_params)

    return render :new, status: :bad_request unless @invite_user_to_team_form.valid?

    invitation = InviteUserToTeam.call(form_params.merge({ inviting_user: current_user }))

    redirect_to @team, flash: { success: t("invite_user_to_team.invite_sent", email: invitation.user.email) }
  end

  def resend
    user = @team.users.find(params[:id])

    invitation = InviteUserToTeam.call({ user: user, team: @team, inviting_user: current_user })

    redirect_to @team, flash: { success: t("invite_user_to_team.invite_sent", email: invitation.user.email) }
  end

private

  def get_team
    @team = Team.find(params[:team_id])
  end

  def authorize_team_invite
    authorize @team, :invite_user?
  end

  def current_operation
    SecondaryAuthentication::INVITE_USER
  end

  def form_params
    params.require(:invite_user_to_team_form).permit(:email).merge({ team: @team })
  end
end
