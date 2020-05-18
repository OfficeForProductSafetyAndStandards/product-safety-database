class ComplainantDecorator < ApplicationDecorator
  delegate_all

  def other_details
    h.simple_format(object.other_details)
  end

  def contact_details
    details = [
      name,
      phone_number,
      email_address,
      object.other_details
    ].compact

    h.simple_format(details.join("\n\n"))
  end
end
