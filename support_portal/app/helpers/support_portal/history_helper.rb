module SupportPortal
  module HistoryHelper
    def display_action(action)
      case action.item_type
      when "User"
        display_action_user(action)
      when "Role"
        case action.event
        when "create"
          "Role added for #{user_email(action.entity_id)}"
        when "update"
          "Role changed for #{user_email(action.entity_id)}"
        when "destroy"
          "Role removed for #{user_email(action.entity_id)}"
        end
      end
    end

    def display_action_user(action)
      object_changes = YAML.safe_load(action.object_changes, permitted_classes: [Time])

      # Special handling when `deleted_at` is changed
      if action.event == "update" && object_changes.keys.first == "deleted_at"
        event_type = object_changes[object_changes.keys.first][1].nil? ? "undestroy" : "destroy"
        return "User #{user_email(action.entity_id)} #{user_event_type(event_type)}"
      end

      "User #{user_email(action.entity_id)} #{object_changes.keys.first.humanize(capitalize: false) if action.event == 'update'} #{user_event_type(action.event)}"
    end

    def display_action_change(action)
      object_changes = YAML.safe_load(action.object_changes, permitted_classes: [Time])

      # Blank when a user is created, deleted or recovered since there's nothing to show
      return "" if action.item_type == "User" && (%w[create destroy].include?(action.event) || object_changes.keys.first == "deleted_at")

      # Special handling when a role is created or destroyed to not display a "from" and "to"
      return object_changes[object_changes.keys.first].compact.last&.humanize if action.item_type == "Role" && %w[create destroy].include?(action.event)

      "From: #{object_changes[object_changes.keys.first][0] || '<em>Empty</em>'}<br>To: #{object_changes[object_changes.keys.first][1] || '<em>Empty</em>'}"
    end

    def user_email(user_id)
      ::User.where(id: user_id).first&.email
    end

    def user_event_type(event)
      {
        "create" => "created",
        "update" => "updated",
        "destroy" => "deleted",
        "undestroy" => "recovered"
      }[event]
    end
  end
end
