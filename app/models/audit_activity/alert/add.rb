class AuditActivity::Alert::Add < AuditActivity::Base
  extend ActionView::Helpers::NumberHelper
  belongs_to :investigation

  def self.build_metadata(alert, user_count)
    {
      user_count: user_count,
      subject: alert.summary,
      date_sent: alert.created_at,
      description: alert.description
    }
  end
end
