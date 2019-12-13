class ComplainantDecorator < ApplicationDecorator
  delegate_all

  def contact_details
    details = [name, phone_number, email_address, other_details].compact

    return "Not provided" if details.empty?

    h.simple_format(details.join("\n\n"))
  end
end
