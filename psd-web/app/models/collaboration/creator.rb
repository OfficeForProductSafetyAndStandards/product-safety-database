class Collaboration < ApplicationRecord
  class Creator < Collaboration
    # optional is true, as its instance of collaborator relation, defined in collaboration
    belongs_to :creator_user, polymorphic: true, foreign_type: "collaborator_type", foreign_key: :collaborator_id, optional: true, autosave: true
    belongs_to :creator_team, polymorphic: true, foreign_type: "collaborator_type", foreign_key: :collaborator_id, optional: true, autosave: true
  end
end
