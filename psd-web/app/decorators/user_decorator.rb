class UserDecorator < Draper::Decorator
  delegate_all

  def assignee_short_name(viewing_user:)
    return "Unknown" if viewing_user.nil?
    return organisation.name if organisation != viewing_user.organisation

    name
  end

  def full_name
    name + deleted_suffix
  end

  def display_name(ignore_visibility_restrictions: false, other_user: User.current)
    suffix = if (ignore_visibility_restrictions || (organisation_id == other_user&.organisation_id)) && teams.any?
               "(#{team_names})"
             else
               "(#{organisation.name})"
             end
    suffix << deleted_suffix

    "#{name} #{suffix}"
  end

private

  def deleted_suffix
    deleted? ? " [user deleted]" : ""
  end
end
