class Collaboration < ApplicationRecord
  class Access < Collaboration
    class OwnerUser < Owner
      belongs_to :user, polymorphic: true, foreign_type: "collaborator_type", foreign_key: :collaborator_id, autosave: true
    end
  end
end
