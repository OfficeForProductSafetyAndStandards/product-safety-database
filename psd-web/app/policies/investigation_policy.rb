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

  def update?
    visible_to(user: @user)
  end

  def assign?(user: @user)
    can_be_assigned_by(user: user)
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
    return true if @record.assignable.present? && (@record.assignable&.organisation == user.organisation)
    return true if @record.source&.user_has_gdpr_access?(user: user)

    # Have any of the user’s teams been added to the case as a collaborator?
    return true if (@record.teams & user.teams).any?

    false
  end

  def can_be_assigned_by(user: @user)
    return true if @record.assignable.blank?
    return true if @record.assignable.is_a?(Team) && (user.teams.include? @record.assignable)
    return true if @record.assignable.is_a?(User) && (user.teams & @record.assignable.teams).any? || @record.assignable == user

    false
  end

  def user_allowed_to_raise_alert?(user: @user)
    user.is_opss?
  end

  def investigation_restricted?
    !@record.is_private
  end

  def add_collaborators?
    return true if @record.assignable.is_a?(Team) && (user.teams.include? @record.assignable)
    return true if @record.assignable.is_a?(User) && (user.teams & @record.assignable.teams).any?
  end
end
