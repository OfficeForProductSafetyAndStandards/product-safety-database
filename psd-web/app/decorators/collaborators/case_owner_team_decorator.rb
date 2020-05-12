module Collaborators
  class CaseOwnerTeamDecorator < Draper::Decorator
    delegate_all
    decorates_association :collaborating
  end
end
