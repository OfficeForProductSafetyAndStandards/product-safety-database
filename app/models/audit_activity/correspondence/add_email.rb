class AuditActivity::Correspondence::AddEmail < AuditActivity::Correspondence::Base
  belongs_to :correspondence, class_name: "Correspondence::Email"
  include ActivityAttachable
  with_attachments email_file: "email file", email_attachment: "email attachment"

  def subtitle_slug
    "Email recorded"
  end
end
