class InvestigationPolicy < ApplicationPolicy
  def show?(user: @user)
    visible_to(user: user)
  end

  def new?
    visible_to(user: @user)
  end

  def status?
    visible_to(user: @user)
  end

  def update?(user: @user)
    record.teams_with_access.include?(user.team)
  end

  def change_owner?(user: @user)
    can_change_owner(user: user)
  end

  def visibility?(user: @user)
    visible_to(user: user, private: true)
  end

  def edit_summary?
    visible_to(user: @user)
  end

  def created?
    visible_to(user: @user)
  end

  def visible_to(user:, private: @record.is_private)
    return true unless private
    return true if user.is_opss?
    return true if @record.owner.present? && (@record.owner&.organisation == user.organisation)
    return true if @record.source&.user_has_gdpr_access?(user: user)

    # Has the user's team been added to the case as a collaborator?
    return true if @record.teams.include?(user.team)

    false
  end

  def can_change_owner(user: @user)
    @record.owner.blank? || @record.owner.in_same_team_as?(user) || @record.owner == user
  end

  def user_allowed_to_raise_alert?(user: @user)
    user.is_opss?
  end

  def investigation_restricted?
    !@record.is_private
  end

  def manage_collaborators?
    return false if @record.owner.nil?

    @record.owner.in_same_team_as?(user)
  end
end
