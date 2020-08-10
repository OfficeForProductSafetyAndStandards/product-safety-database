class TeamPolicy < ApplicationPolicy
  def show?(user: @user, team: @record)
    user.team == team
  end

  def invite_user?(user: @user, team: @record)
    user.is_team_admin? && user.team == team
  end
end
