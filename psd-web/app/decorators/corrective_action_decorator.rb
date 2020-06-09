class CorrectiveActionDecorator < ApplicationDecorator
  delegate_all
  include SupportingInformationHelper

  def details
    h.simple_format(object.details)
  end
end
