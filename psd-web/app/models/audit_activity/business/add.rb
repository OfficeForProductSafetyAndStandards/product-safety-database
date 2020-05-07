class AuditActivity::Business::Add < AuditActivity::Business::Base
  def self.from(business, investigation)
    title = business.trading_name
    relationship = investigation.investigation_businesses.find_by(business_id: business.id).relationship
    body = "Role: **#{sanitize_text relationship}**"
    super(business, investigation, title, body)
  end

  def email_update_text(viewing_user = nil)
    "Business was added to the #{investigation.case_type} by #{source&.show(viewing_user)}."
  end

private

  def subtitle_slug
    "Business added"
  end
end
