module Investigations::UserFiltersHelper
  def entities
    User.get_owners(except: current_user).decorate + Team.not_deleted.decorate
  end

  def teams_added_to_case_items(form)
    [
      { key: "teams_with_access[my_team]", value: current_user.team_id, text: t(".my_team"), unchecked_value: "", checked: form.object.teams_with_access_ids.detect { |team_with_access_id| team_with_access_id == current_user.team_id } },
      {
        key: "teams_with_access[other_team_with_access]",
        value: true,
        unchecked_value: "off",
        checked: form.object.teams_with_access.other_team_with_access,
        text: t(".other_team"),
        conditional: { html: other_teams(form) }
      }
    ]
  end

  def case_owner_is(form)
    case_owner_is_items = [{ key: "case_owner_is_me", value: true, unchecked_value: "off", text: "Me" }]
    case_owner_is_items << { key: "case_owner_is_my_team", value: true, unchecked_value: "off", text: "My team", checked: form.object.case_owner_is_my_team? }
    case_owner_is_items << { key: "case_owner_is_someone_else",
                             value: true,
                             unchecked_value: "off",
                             text: "Other person or team",
                             conditional: { html: other_owner(form) } }
  end

  def created_by(form)
    created_by_items = [{ key: "created_by_me", value: "checked", unchecked_value: "unchecked", text: "Me" }]
    created_by_items << { key: creator_team_with_key[0], value: creator_team_with_key[1].id, unchecked_value: "unchecked", text: creator_team_with_key[2] }
    created_by_items << { key: "created_by_someone_else",
                          value: "checked",
                          unchecked_value: "unchecked",
                          text: "Other person or team",
                          conditional: { html: other_creator(form) } }
  end

  def other_owner(form)
    render "form_components/govuk_select",
           key: :case_owner_is_someone_else_id,
           form: form,
           items: entities.map { |e| { text: e.display_name(viewer: current_user), value: e.id } },
           label: { text: "Name" },
           is_autocomplete: true
  end

  def other_teams(form)
    other_teams = Team.not_deleted.where.not(id: current_user.team)

    render "form_components/govuk_select",
           key: "teams_with_access[id][]",
           form: form,
           items: other_teams.map { |e| { text: e.display_name(viewer: current_user), value: e.id, selected: form.object.teams_with_access_ids.detect { |team_with_access_id| team_with_access_id == e.id } } },
           label: { text: "Name" },
           is_autocomplete: true
  end

  def other_creator(form)
    render "form_components/govuk_select",
           key: :created_by_someone_else_id,
           form: form,
           items: entities.map { |e| { text: e.display_name(viewer: current_user), value: e.id } },
           label: { text: "Name" },
           is_autocomplete: true
  end
end
