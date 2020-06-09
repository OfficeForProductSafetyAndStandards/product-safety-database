class Collaboration < ApplicationRecord
  class EditAccess < Access
    # optional is true, as its instance of collaborator relation, defined in collaboration
    belongs_to :editor, polymorphic: true, foreign_type: "collaborator_type", foreign_key: :collaborator_id, optional: true
    belongs_to :added_by_user, class_name: :User

    validates :message, presence: true, if: :include_message

    validates :include_message, inclusion: { in: [true, false] }

    attr_reader :include_message

    def include_message=(value)
      @include_message = if value.is_a? String
                           (value == "true")
                         else
                           value
                         end
    end
  end
end
