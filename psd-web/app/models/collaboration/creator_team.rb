class Collaboration < ApplicationRecord
  class CreatorTeam < Creator
    belongs_to :creator_team, polymorphic: true, foreign_type: "collaborator_type", foreign_key: :collaborator_id, autosave: true
  end
end
