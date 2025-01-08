class CorrespondenceDecorator < ApplicationDecorator
  include SupportingInformationHelper
  delegate_all

  def title
    overview.presence
  end

  def supporting_information_title
    title
  end

  def date_of_activity
    correspondence_date.to_formatted_s(:govuk)
  end

  def date_of_activity_for_sorting
    correspondence_date
  end

  def date_added
    created_at.to_formatted_s(:govuk)
  end

  def supporting_information_type
    "Correspondence#{h.tag.span(super, class: 'govuk-caption-m')}".html_safe
  end

  def event_type
    return "Telephone" if object.class.model_name.human == "Phone call"

    object.class.model_name.human
  end

  def activity_cell_partial(viewing_user)
    return "activity_table_cell_no_link" unless Pundit.policy!(viewing_user, investigation).view_protected_details?(user: viewing_user)

    super
  end
end
