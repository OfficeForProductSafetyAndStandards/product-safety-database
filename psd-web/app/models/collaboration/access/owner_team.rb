class Collaboration < ApplicationRecord
  class Access < Collaboration
    class OwnerTeam < Owner
      def swap_to_edit_access!
        update!(type: "Collaboration::Access::Edit")
        investigation.owner_user_collaboration.destroy!
      end
    end
  end
end
