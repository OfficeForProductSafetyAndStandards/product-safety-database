class UserDecorator < Draper::Decorator
  delegate_all

  def assignee_short_name(viewing_user:)
    return "Unassigned" if viewing_user.nil?
    return organisation.name if organisation != viewing_user.organisation

    name
  end

  def errors
    h.govukErrorSummary(
      titleText: "There is a problem",
      errorList: object.errors.full_messages.map { |error| { text: error, href: "#new_user" } }
    ) if object.errors.any?
  end
end
