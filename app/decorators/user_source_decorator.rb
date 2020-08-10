class UserSourceDecorator < ApplicationDecorator
  delegate_all
  decorates_associations :user
end
