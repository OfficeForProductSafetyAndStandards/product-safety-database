class AuditActivity::Investigation::UpdateReferenceNumberDecorator < ApplicationDecorator
  delegate_all

  def new_reference_number
    metadata.dig("updates", "complainant_reference", 1)
  end

  def title(_viewer)
    "Reference number updated"
  end
end
