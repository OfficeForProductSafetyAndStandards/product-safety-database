class AuditActivity::DocumentUpload::Base < AuditActivity::Base
  def has_attachment?
    true
  end

  def attachment_type
    attached_image? ? "Image" : "Document"
  end

  def attached_image?
    file_upload.image?
  end

  def restricted_title(_user); end

  def can_display_all_data?(user)
    attached_image? || Pundit.policy(user, investigation).view_protected_details?
  end
end
