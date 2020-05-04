class AuditActivity::Document::Base < AuditActivity::Base
  include ActivityAttachable
  include GdprHelper
  with_attachments attachment: "document"

  private_class_method def self.from(document, investigation, title)
    activity = create(
      body: sanitize_text(document.metadata[:description]),
      source: UserSource.new(user: User.current),
      investigation: investigation,
      title: title
    )
    activity.attach_blob document
  end

  def attachment_type
    attached_image? ? "Image" : "Document"
  end

  def attached_image?
    attachment.image?
  end

  def restricted_title; end

  def can_display_all_data?
    can_be_displayed?(attachment, investigation)
  end
end
