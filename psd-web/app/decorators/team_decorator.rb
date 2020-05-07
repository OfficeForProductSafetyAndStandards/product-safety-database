class TeamDecorator < Draper::Decorator
  delegate_all

  def owner_short_name(*)
    display_name
  end

  def display_name(ignore_visibility_restrictions: false, other_user: User.current)
    other_user ||= User.current

    return name if (other_user && (other_user.organisation_id == organisation_id)) || ignore_visibility_restrictions

    organisation.name
  end
end
