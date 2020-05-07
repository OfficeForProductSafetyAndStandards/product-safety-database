class UserDecorator < Draper::Decorator
  delegate_all

  def owner_short_name(viewing_user:)
    return "Unknown" if viewing_user.nil?
    return organisation.name if organisation != viewing_user.organisation

    name
  end

  def full_name
    name + deleted_suffix
  end

  def display_name(other_user: User.current)
    suffix = " (#{team.name})" if team_id != other_user&.team_id
    "#{name}#{suffix}#{deleted_suffix}"
  end

private

  def deleted_suffix
    deleted? ? " [user deleted]" : ""
  end
end
