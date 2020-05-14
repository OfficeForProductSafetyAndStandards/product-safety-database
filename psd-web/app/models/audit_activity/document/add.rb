class AuditActivity::Document::Add < AuditActivity::Document::Base
  def self.from(document, investigation)
    title = document.metadata[:title] || "Untitled document"
    super(document, investigation, title)
  end

  def email_update_text(viewer = nil)
    "Document was attached to the #{investigation.case_type.upcase_first} by #{source&.show(viewer)}."
  end

  def restricted_title
    "Document added"
  end

private

  def subtitle_slug
    "#{attachment_type} added"
  end
end
