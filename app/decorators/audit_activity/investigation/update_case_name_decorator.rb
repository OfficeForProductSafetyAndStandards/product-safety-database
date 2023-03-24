class AuditActivity::Investigation::UpdateCaseNameDecorator < ApplicationDecorator
  delegate_all

  def new_case_name
    metadata.dig("updates", "user_title", 1)
  end

  def title(_viewer)
    "Case name updated"
  end
end
