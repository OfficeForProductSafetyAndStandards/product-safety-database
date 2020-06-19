class ActivityDecorator < ApplicationDecorator
  delegate_all

  def protected_details_type
    "#{investigation.case_type} contact details"
  end
end
