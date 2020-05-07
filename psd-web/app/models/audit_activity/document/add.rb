class AuditActivity::Document::Add < AuditActivity::Document::Base
  def self.from(document, investigation)
    title = document.metadata[:title] || "Untitled document"
    super(document, investigation, title)
  end

  def email_update_text(viewing_user = nil)
    "Document was attached to the #{investigation.case_type.upcase_first} by #{source&.show(viewing_user)}."
  end

  def restricted_title
    "Document added"
  end

private

  def subtitle_slug
    "#{attachment_type} added"
  end
end
