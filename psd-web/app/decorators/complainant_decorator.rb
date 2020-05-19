class ComplainantDecorator < ApplicationDecorator
  delegate_all
  decorates_associations :investigation

  def other_details
    h.simple_format(object.other_details)
  end

  def contact_details(viewing_user)
    details = [investigation.hint_for_contact_details]

    if investigation.collaborators.where(team: viewing_user.team).exists?
      details << name
      details << phone_number
      details << email_address
      details << object.other_details

      details.compact!
    end

    h.simple_format(details.join("\n\n"))
  end
end
