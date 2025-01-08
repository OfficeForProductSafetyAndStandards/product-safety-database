class ProductPolicy < ApplicationPolicy
  def show?
    return true if record.not_retired?

    user.is_opss?
  end

  def export?
    user.all_data_exporter?
  end

  def update?
    return false if record.version.present?
    return false if record.retired?

    # superusers are allowed to edit any product record
    record.owning_team == user.team || record_is_unowned_and_attatched_to_an_open_case_owned_by_users_team? || user.is_superuser?
  end

  def can_spawn_case?
    record.not_retired?
  end

  def can_view_retired_products?
    user.is_opss?
  end

private

  def record_is_unowned_and_attatched_to_an_open_case_owned_by_users_team?
    return false if record.owning_team.present?

    Collaboration::Access::OwnerTeam.joins(:investigation).where(collaborator_id: user.team_id, investigations: { id: record.investigation_ids, is_closed: false }).any?
  end
end
