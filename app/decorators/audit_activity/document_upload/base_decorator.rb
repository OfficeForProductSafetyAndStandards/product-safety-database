class AuditActivity::DocumentUpload::BaseDecorator < ApplicationDecorator
  delegate_all

  def protected_details_type
    "attachments"
  end
end
