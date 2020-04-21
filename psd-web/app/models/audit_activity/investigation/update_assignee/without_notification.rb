class AuditActivity::Investigation::UpdateAssignee::WithoutNotification < AuditActivity::Investigation::UpdateAssignee::Base
  def entities_to_notify
    []
  end

  def email_subject_text; end

  def email_update_text; end
end
