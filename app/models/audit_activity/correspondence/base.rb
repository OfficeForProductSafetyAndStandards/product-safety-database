class AuditActivity::Correspondence::Base < AuditActivity::Base
  belongs_to :correspondence

  def can_display_all_data?(user)
    Pundit.policy(user, investigation).view_protected_details?
  end
end
