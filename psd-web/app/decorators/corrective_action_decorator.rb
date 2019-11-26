class CorrectiveActionDecorator < ApplicationDecorator
  delegate_all
  def details
    h.simple_format(object.details)
  end
end
