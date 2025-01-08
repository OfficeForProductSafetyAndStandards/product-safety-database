class AuditActivity::Investigation::AutomaticallyClosedCase < AuditActivity::Investigation::Base
  def self.build_metadata(notification)
    {
      notification_id: notification.id,
      title: notification.user_title,
      closed_at: Time.current
    }
  end

  def title(_user = nil)
    "Draft notification automatically closed"
  end
end
