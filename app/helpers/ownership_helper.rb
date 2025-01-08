module OwnershipHelper
  def add_your_team_values(items, investigation, someone_else_in_your_team_dropdown)
    items << { divider: "Your team" }

    items << { text: investigation.owner.decorate.display_name(viewer: current_user), value: investigation.owner.id, checked: true }

    unless investigation.owner == current_user
      items << { text: current_user.decorate.display_name(viewer: current_user), value: current_user.id, checked: false }
    end

    items << { text: "Someone else in your team", value: "someone_else_in_your_team", conditional: { html: someone_else_in_your_team_dropdown } }

    unless investigation.owner == current_user.team
      items << { text: current_user.team.decorate.display_name(viewer: current_user), value: current_user.team.id, checked: false }
    end

    items
  end

  def opss_hint_text(team)
    return unless team.name == "OPSS Incident Management"
    return if current_user.is_opss?

    "For reporting serious risks to OPSS"
  end
end
