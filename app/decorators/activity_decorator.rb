class ActivityDecorator < ApplicationDecorator
  delegate_all

  def protected_details_type
    "notification contact details"
  end
end
