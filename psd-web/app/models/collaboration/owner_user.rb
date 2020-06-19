class Collaboration < ApplicationRecord
  class OwnerUser < Owner
    belongs_to :owner_user, polymorphic: true, foreign_type: "collaborator_type", foreign_key: :collaborator_id, autosave: true
  end
end
