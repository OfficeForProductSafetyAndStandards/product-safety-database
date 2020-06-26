class CorrectiveActionDecorator < ApplicationDecorator
  delegate_all
  include SupportingInformationHelper
  include SupportingInformation::CorrectiveActionSortInterface

  def details
    return if object.details.blank?

    h.simple_format(object.details)
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

  def measure_type
    object.measure_type&.upcase_first
  end

  def duration
    object.duration.upcase_first
  end
end
