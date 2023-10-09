class AuditActivity::ImageUpload::BaseDecorator < ApplicationDecorator
  delegate_all

  def protected_details_type
    "images"
  end
end
