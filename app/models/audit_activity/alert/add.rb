class AuditActivity::Alert::Add < AuditActivity::Base
  belongs_to :investigation, class_name: "::Investigation"

  def self.build_metadata(alert)
    {
      user_count: User.active.count,
      subject: alert.summary,
      date_sent: alert.created_at,
      description: alert.description
    }
  end

  def title(_current_user)
    "Product safety alert sent"
  end
end
