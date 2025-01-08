class UserDecorator < Draper::Decorator
  delegate_all

  def owner_short_name(viewer:)
    return "Unknown" if viewer.nil?
    return organisation.name if organisation != viewer.organisation

    name
  end

  def full_name
    name + deleted_suffix
  end

  # viewer could be a Team or User
  def display_name(viewer:)
    suffix = " (#{team.name})" if team != viewer&.team
    "#{name}#{suffix}#{deleted_suffix}"
  end

private

  def deleted_suffix
    deleted? ? " [user deleted]" : ""
  end
end
