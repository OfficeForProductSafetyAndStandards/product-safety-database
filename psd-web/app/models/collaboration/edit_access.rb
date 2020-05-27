class Collaboration < ApplicationRecord
  class EditAccess < Access
    # optional is true, as its instance of collaborator relation, defined in collaboration
    belongs_to :editor, polymorphic: true, foreign_type: "collaborator_type", foreign_key: :collaborator_id, optional: true
  end
end
