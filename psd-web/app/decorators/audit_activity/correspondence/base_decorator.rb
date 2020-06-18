class AuditActivity::Correspondence::BaseDecorator < ApplicationDecorator
  delegate_all

  def protected_details_type
    "correspondence"
  end
end
