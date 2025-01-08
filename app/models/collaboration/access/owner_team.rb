class Collaboration < ApplicationRecord
  class Access < Collaboration
    class OwnerTeam < Owner
      def swap_to_edit_access!
        transaction do
          destroy!
          investigation.owner_user_collaboration&.destroy!
          investigation.edit_access_collaborations.create!(collaborator:)
        end
      end
    end
  end
end
