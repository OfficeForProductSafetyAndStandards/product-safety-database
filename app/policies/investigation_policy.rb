class InvestigationPolicy < ApplicationPolicy
  # Determines if the user has read-only access to the case
  def readonly?
    record.teams_with_read_only_access.include?(user.team)
  end

  # Determines if the user can update the case details and related records
  # This includes adding/removing products, businesses, documents, etc.
  # Does not include changing ownership, status, or restriction level
  def update?(user: @user)
    return false if record.is_closed? && !user.has_role?(:super_user)

    record.teams_with_edit_access.include?(user.team) || user.has_role?(:super_user)
  end

  def delete?(user: @user)
    record.draft? && (record.owner == user || user.has_role?(:super_user))
  end

  # Determines if the user can change case ownership, status, or restriction level
  def change_owner_or_status?(user: @user)
    record.owner.in_same_team_as?(user) || record.owner == user || user.has_role?(:super_user)
  end

  # Determines if the user can manage team collaborations and permission levels
  def manage_collaborators?
    return false if record.is_closed?
    return false if record.owner.nil?

    @record.owner.in_same_team_as?(user) || user.has_role?(:super_user)
  end

  def can_unrestrict?(user: @user)
    change_owner_or_status?(user:) && record.is_private? || user.has_role?(:super_user)
  end

  # Determines if the user can view basic case details
  # Protected details like personal contact info remain hidden
  def view_non_protected_details?(user: @user, private: @record.is_private)
    return true unless private

    user.can_view_restricted_cases? || @record.teams_with_access.include?(user.team) || user.has_role?(:super_user)
  end

  def view_protected_details?(user: @user)
    user.can_view_restricted_cases? || @record.teams_with_access.include?(user.team) || user.has_role?(:super_user)
  end

  def investigation_restricted?
    !@record.is_private
  end

  def export?
    user.all_data_exporter?
  end

  def risk_level_validation?
    user.can_validate_risk_level?
  end

  def view_notifying_country?(user: @user)
    record.notifying_country.present? || user.is_opss? || user.has_role?(:super_user)
  end

  def change_notifying_country?(user: @user)
    user.notifying_country_editor? || user.has_role?(:super_user)
  end

  def view_overseas_regulator?(user: @user)
    user.is_opss? || user.has_role?(:super_user)
  end

  def change_overseas_regulator?(user: @user)
    user.is_opss? || user.has_role?(:super_user)
  end

  def comment?
    return false if record.is_closed?

    show?
  end

  def can_be_deleted?
    record.products.none?
  end

  # Determines if the user can access a draft notification
  # Only creators and owners can access draft notifications
  def can_access_draft?
    return true unless record.is_a?(Investigation::Notification) && record.draft?

    [record.creator_user, record.owner].include?(user)
  end
end
