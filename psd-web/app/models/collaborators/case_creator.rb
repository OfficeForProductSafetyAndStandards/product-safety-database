module Collaborators
  class CaseCreator < Base
    self.abstract_class = true

    def user_has_gdpr_access?(*)
      true
    end
  end
end
