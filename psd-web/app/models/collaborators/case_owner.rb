module Collaborators
  class CaseOwner < Current
    self.abstract_class = true

    def make_collaborator!(attributes)
      attributes[:type] = "Collaborator"
      update!(attributes)
    end

  end
end
