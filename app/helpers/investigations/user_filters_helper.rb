module Investigations::UserFiltersHelper
  def entities
    User.get_owners(except: current_user).decorate + Team.not_deleted.decorate
  end

  def created_by(form)
    govukSelect(
      key: :created_by_other_id,
      form:,
      items: entities.map { |e| { text: e.display_name(viewer: current_user), value: e.id, selected: form.object.teams_with_access_other_id == e.id } },
      label: { text: "Person or team name" },
      include_blank: true
    )
  end

  def other_owner(form)
    govukSelect(
      key: :case_owner_is_someone_else_id,
      form:,
      items: entities.map { |e| { text: e.display_name(viewer: current_user), value: e.id } },
      label: { text: "Person or team name" },
      include_blank: true
    )
  end

  def other_teams(form)
    other_teams = Team.not_deleted.where.not(id: current_user.team)
    govukSelect(
      key: :teams_with_access_other_id,
      form:,
      items: other_teams.map { |e| { text: e.display_name(viewer: current_user), value: e.id, selected: form.object.teams_with_access_other_id == e.id } },
      label: { text: "Team name" },
      include_blank: true
    )
  end

  def other_creator(form)
    govukSelect(
      key: :created_by_other,
      form:,
      items: entities.map { |e| { text: e.display_name(viewer: current_user), value: e.id, selected: form.object.created_by.id == e.id } },
      label: { text: "Name" },
      include_blank: true
    )
  end
end
