class AuditActivity::Investigation::AddProject < AuditActivity::Investigation::Add
  def self.from(investigation)
    super(investigation, self.build_title(investigation), self.build_body(investigation))
  end

  def self.build_title(investigation)
    "Project logged: #{investigation.decorate.title}"
  end

  def self.build_body(investigation)
    body =  "**Project details**<br>"
    body += "<br>Case is related to the coronavirus outbreak.<br>" if investigation.coronavirus_related?
    body += "<br>#{self.sanitize_text investigation.description}" if investigation.description.present?
    body += self.build_assignee_details(investigation) if investigation.owner.present?
    body
  end

  def can_display_all_data?
    true
  end
end
