class AuditActivity::Correspondence::AddPhoneCall < AuditActivity::Correspondence::Base
  belongs_to :correspondence, class_name: "Correspondence::PhoneCall"
  include ActivityAttachable
  with_attachments attachment: "attachment"

  def self.from(correspondence, investigation)
    activity = super(correspondence, investigation, build_body(correspondence))
    activity.attach_blob(correspondence.transcript.blob, :attachment) if correspondence.transcript.attached?
  end

  def self.build_body(correspondence)
    output = ""
    output += build_correspondent_details correspondence
    output += "Date: **#{correspondence.correspondence_date.strftime('%d/%m/%Y')}**<br>" if correspondence.correspondence_date.present?
    output += build_file_body correspondence
    output += "<br>#{sanitize_text correspondence.details}"
    output
  end

  def self.build_correspondent_details(correspondence)
    return "" unless correspondence.correspondent_name || correspondence.phone_number

    output = "Call with: "
    output += "**#{sanitize_text correspondence.correspondent_name}** " if correspondence.correspondent_name.present?
    output += build_phone_number correspondence if correspondence.phone_number.present?
    output
  end

  def self.build_phone_number(correspondence)
    output = ""
    output += "(" if correspondence.correspondent_name.present?
    output += sanitize_text correspondence.phone_number
    output += ")" if correspondence.correspondent_name.present?
    output + "<br>"
  end

  def self.build_file_body(correspondence)
    file = correspondence.transcript
    file.attached? ? "Attached: #{sanitize_text file.filename}<br>" : ""
  end

  def restricted_title(_user)
    "Phone call added"
  end

  def activity_type
    "phone call"
  end

  def email_update_text(viewer = nil)
    "Phone call details added to the #{investigation.case_type.upcase_first} by #{source&.show(viewer)}."
  end

private

  def subtitle_slug
    "Phone call"
  end
end
