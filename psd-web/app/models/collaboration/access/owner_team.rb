class Collaboration < ApplicationRecord
  class Access < Collaboration
    class OwnerTeam < Owner
      def swap_to_edit_access!
        investigation.edit_access_collaborations.create!(collaborator: collaborator)
        destroy!
        investigation.owner_user_collaboration&.destroy!
      end
    end
  end
end
