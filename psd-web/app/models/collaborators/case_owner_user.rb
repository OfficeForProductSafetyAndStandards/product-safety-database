module Collaborators
  class CaseOwnerUser < CaseOwner

    def make_collaborator!(*)
      destroy!
    end
  end
end
