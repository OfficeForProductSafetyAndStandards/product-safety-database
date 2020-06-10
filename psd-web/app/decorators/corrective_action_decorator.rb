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
    date_decided
  end

  def date_added
    created_at.to_s(:govuk)
  end
end
