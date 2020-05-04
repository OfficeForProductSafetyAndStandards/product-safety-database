class AuditActivity::Investigation::AddAllegation < AuditActivity::Investigation::Add
  def self.from(investigation)
    super(investigation, build_title(investigation), build_body(investigation))
  end

  def self.build_title(investigation)
    "Allegation logged: #{investigation.decorate.title}"
  end

  def self.build_body(investigation)
    body =  "**Allegation details**<br>"
    body += "<br>Case is related to the coronavirus outbreak." if investigation.coronavirus_related?
    body += "<br>Product category: **#{investigation.product_category}**" if investigation.product_category.present?
    body += "<br>Hazard type: **#{investigation.hazard_type}**" if investigation.hazard_type.present?
    body += "<br>Attachment: **#{sanitize_text investigation.documents.first.filename}**" if investigation.documents.attached?
    body += "<br><br>#{sanitize_text investigation.description}" if investigation.description.present?
    body += build_complainant_details(investigation.complainant) if investigation.complainant.present?
    body += build_owner_details(investigation) if investigation.owner.present?
    body
  end
end
