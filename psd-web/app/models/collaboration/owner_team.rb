class Collaboration < ApplicationRecord
  class OwnerTeam < Owner
    belongs_to :owner_team, polymorphic: true, foreign_type: "collaborator_type", foreign_key: :collaborator_id, autosave: true
  end
end
