class AuditActivity::ImageUpload::Base < AuditActivity::Base
  def has_attachment?
    true
  end

  def restricted_title(_user); end

  def can_display_all_data?(_user)
    true
  end
end
