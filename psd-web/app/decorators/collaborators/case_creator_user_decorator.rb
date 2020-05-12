module Collaborators
  class CaseCreatorUserDecorator < Draper::Decorator
    delegate_all
    decorates_association :collaborating
  end
end
