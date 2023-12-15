module SupportPortal
  module ActivityHelper

    def display_activity_description(activity)
      activity_sub_type = activity.type.split("::")
      activity_sub_type.shift
      activity_desc = activity_sub_type.join(" ").titleize.humanize

      content_tag(:span) do
        concat(content_tag(:strong, activity_desc))
        concat(content_tag(:br))
        concat(activity.title)
      end
    end

    def display_activity_metadata(activity)
      pretty_json = JSON.pretty_generate(activity.metadata)
      content_tag(:pre, pretty_json)
    end
  end
end
