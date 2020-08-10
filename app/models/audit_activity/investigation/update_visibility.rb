class AuditActivity::Investigation::UpdateVisibility < AuditActivity::Investigation::Base
  def self.from(investigation)
    title = "#{investigation.case_type.upcase_first} visibility
            #{investigation.is_private ? 'restricted' : 'unrestricted'}"
    super(investigation, title, sanitize_text(investigation.visibility_rationale))
  end

  def email_update_text(viewer = nil)
    "#{investigation.case_type.upcase_first} visibility was #{investigation.is_private ? 'restricted' : 'unrestricted'} by #{source&.show(viewer)}."
  end
end
