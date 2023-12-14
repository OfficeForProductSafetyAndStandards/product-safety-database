class ActivityDecorator < ApplicationDecorator
  delegate_all

  def protected_details_type
    "case contact details"
  end
end
