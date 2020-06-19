class Collaboration < ApplicationRecord
  class Access < Collaboration
    class OwnerTeam < Owner
      # belongs_to :team, polymorphic: true, foreign_type: "collaborator_type", foreign_key: :collaborator_id
    end
  end
end
