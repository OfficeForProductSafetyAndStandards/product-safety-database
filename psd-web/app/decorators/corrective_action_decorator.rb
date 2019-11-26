class CorrectiveActionDecorator < ApplicationDecorator

  def details
    h.simple_format(object.details)
  end

end
