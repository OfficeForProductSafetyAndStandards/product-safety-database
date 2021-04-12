class AuditActivity::Business::Destroy < AuditActivity::Business::Base

  def self.from(_business, _investigation)
    raise "Deprecated - use RemoveBusinessFromCase.call instead"
  end

  def email_update_text(viewer = nil)
    "Business was removed from the #{investigation.case_type} by #{source&.show(viewer)}."
  end

private

  def subtitle_slug
    "Business removed"
  end
end
