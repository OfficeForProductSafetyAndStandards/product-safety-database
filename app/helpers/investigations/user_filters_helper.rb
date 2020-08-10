module Investigations::UserFiltersHelper
  def entities
    User.get_owners(except: current_user).decorate + Team.all_with_organisation.decorate
  end

  def case_owner_is(form)
    case_owner_is_items = [{ key: "case_owner_is_me", value: "checked", unchecked_value: "unchecked", text: "Me" }]
    case_owner_is_items << { key: owner_team_with_key[0], value: owner_team_with_key[1].id, unchecked_value: "unchecked", text: owner_team_with_key[2] }
    case_owner_is_items << { key: "case_owner_is_someone_else",
                             value: "checked",
                             unchecked_value: "unchecked",
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

  def other_creator(form)
    render "form_components/govuk_select",
           key: :created_by_someone_else_id,
           form: form,
           items: entities.map { |e| { text: e.display_name(viewer: current_user), value: e.id } },
           label: { text: "Name" },
           is_autocomplete: true
  end
end
