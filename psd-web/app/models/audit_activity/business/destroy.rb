class AuditActivity::Business::Destroy < AuditActivity::Business::Base
  def self.from(business, investigation)
    title = "Removed: #{sanitize_text business.trading_name}"
    super(business, investigation, title, nil)
  end

  def email_update_text(viewing_user = nil)
    "Business was removed from the #{investigation.case_type} by #{source&.show(viewing_user)}."
  end

private

  def subtitle_slug
    "Business removed"
  end
end
