class UserDecorator < Draper::Decorator
  delegate_all

  def assignee_short_name(viewing_user:)
    return "Unassigned" if viewing_user.nil?
    return organisation.name if organisation != viewing_user.organisation

    name
  end

  def name
    if deleted?
      "#{object.name} [user deleted]"
    else
      object.name
    end
  end
end
