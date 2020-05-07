class AuditActivity::Document::Destroy < AuditActivity::Document::Base
  def self.from(document, investigation)
    title = "Deleted: #{document.metadata[:title]}"
    super(document, investigation, title)
  end

  def restricted_title
    "Document deleted"
  end

  def email_update_text(viewing_user = nil)
    "Document attached to the #{investigation.case_type.upcase_first} was removed by #{source&.show(viewing_user)}."
  end

private

  def subtitle_slug
    "#{attachment_type} deleted"
  end
end
