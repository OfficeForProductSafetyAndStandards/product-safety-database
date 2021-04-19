class ComplainantDecorator < ApplicationDecorator
  delegate_all

  def other_details
    h.simple_format(object.other_details)
  end

  def contact_details
    return "Not provided" unless object.has_contact_details?

    h.simple_format(details.join("\n\n"))
  end
end
