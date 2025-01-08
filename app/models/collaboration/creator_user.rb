class Collaboration < ApplicationRecord
  class CreatorUser < Creator
    belongs_to :creator_user, polymorphic: true, foreign_type: "collaborator_type", foreign_key: :collaborator_id, autosave: true
  end
end
