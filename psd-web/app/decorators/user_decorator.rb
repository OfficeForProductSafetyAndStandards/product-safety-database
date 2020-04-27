class UserDecorator < Draper::Decorator
  delegate_all

  def assignee_short_name(viewing_user:)
    return "Unknown" if viewing_user.nil?
    return organisation.name if organisation != viewing_user.organisation

    name
  end
end
