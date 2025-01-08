class AuditActivity::Correspondence::AddEmail < AuditActivity::Correspondence::Base
  belongs_to :correspondence, class_name: "Correspondence::Email"
  include ActivityAttachable
  with_attachments email_file: "email file", email_attachment: "email attachment"

  def subtitle_slug
    "Email recorded"
  end

  def self.build_metadata(email)
    {
      overview: email.overview,
      subject: email.email_subject,
      correspondence_date: email.correspondence_date,
      correspondent_name: email.correspondent_name,
      correspondent_email: email.email_address,
      correspondent_direction: Correspondence::Email.email_directions[email.email_direction],
      email_body: email.details,
      email_attachment_name: email.email_attachment.filename,
      email_attachment_description: email.email_attachment.description,
      email_file_name: email.email_file.filename
    }
  end

  def restricted_title(_user)
    "Email added"
  end
end
