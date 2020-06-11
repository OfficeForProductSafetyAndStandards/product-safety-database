class CorrectiveActionDecorator < ApplicationDecorator
  delegate_all
  include SupportingInformationHelper

  def details
    h.simple_format(object.details)
  end

  def supporting_information_title
    summary
  end

  def date_of_activity
    date_decided.to_s(:govuk)
  end

  def date_added
    created_at.to_s(:govuk)
  end

  def show_path
    h.investigation_action_path(investigation, object)
  end

  def activity_cell_partial(viewing_user)
    return "activity_table_cell_with_link" if Pundit.policy!(viewing_user, investigation).view_protected_details?(user: viewing_user)

    "activity_table_cell_no_link"
  end
end
