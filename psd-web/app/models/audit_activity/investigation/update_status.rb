class AuditActivity::Investigation::UpdateStatus < AuditActivity::Investigation::Base
  def self.from(investigation)
    title = "#{investigation.case_type.upcase_first} #{investigation.is_closed? ? 'closed' : 'reopened'}"
    super(investigation, title, sanitize_text(investigation.status_rationale))
  end

  def email_update_text(viewer = nil)
    "#{email_subject_text} by #{source&.show(viewer)}."
  end

  def email_subject_text
    "#{investigation.case_type.upcase_first} was #{investigation.is_closed? ? 'closed' : 'reopened'}"
  end

private

  def users_to_notify
    return super if investigation.source&.is_a? ReportSource
    return super if source&.user == investigation.source&.user && source.present?

    [investigation.source&.user] + super
  end
end
