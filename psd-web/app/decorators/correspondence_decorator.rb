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
    correspondence_date.to_s(:govuk)
  end

  def date_added
    created_at.to_s(:govuk)
  end
end
