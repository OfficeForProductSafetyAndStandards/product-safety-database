class InvestigationPolicy < ApplicationPolicy
  # Ability to view the entire case including protected details
  def readonly?
    record.teams_with_read_only_access.include?(user.team)
  end

  # Used for all updating of the case, including adding and removing related
  # records, such as products, businesses and documents, with the exception of
  # changing the case owner, its status (eg 'open' or 'closed'), and whether
  # or not it is 'restricted'.
  def update?(user: @user)
    record.teams_with_edit_access.include?(user.team)
  end

  # Ability to change the case owner, the status of the case (eg 'open' or 'closed'),
  # and whether or not it is 'restricted'.
  def change_owner_or_status?(user: @user)
    @record.owner.in_same_team_as?(user) || @record.owner == user
  end

  # Ability to add and remove other teams as collaborators, and to set their
  # permission levels.
  def manage_collaborators?
    return false if @record.owner.nil?

    @record.owner.in_same_team_as?(user)
  end

  # Ability to see most of the details of the case, with the exception of
  # 'protected' details, such as personal contact details or correspondance
  # with businesses.
  def view_non_protected_details?(user: @user, private: @record.is_private)
    return true unless private

    # Has the user's team been added to the case as a collaborator?
    @record.teams_with_access.include?(user.team)
  end

  def view_protected_details?(user: @user)
    @record.teams_with_access.include?(user.team)
  end

  def send_email_alert?(user: @user)
    user.is_opss?
  end

  def investigation_restricted?
    !@record.is_private
  end

  def export?
    user.is_psd_admin?
  end

  def risk_level_validation?
    user.can_validate_risk_level?
  end
end
