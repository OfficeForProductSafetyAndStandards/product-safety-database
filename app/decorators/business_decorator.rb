class BusinessDecorator < ApplicationDecorator
  delegate_all
  decorates_association :investigations
end
