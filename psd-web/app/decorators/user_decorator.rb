class UserDecorator < Draper::Decorator
  delegate_all

  def assignee_short_name(viewing_user:)
    return "Unassigned" if viewing_user.nil?
    return organisation.name if organisation != viewing_user.organisation

    name
  end

  def error_summary
    return unless errors.any?

    error_list = errors.map { |attribute, error| { text: error, href: "##{attribute}" } }
    h.govukErrorSummary(titleText: "There is a problem", errorList: error_list)
  end

end
