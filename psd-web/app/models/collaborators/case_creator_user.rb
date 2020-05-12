module Collaborators
  class CaseCreatorUser < CaseCreator
    def user_has_gdpr_access?(user: User.current)
      user.organisation == collaborating.organisation
    end
  end
end
