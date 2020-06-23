class Collaboration < ApplicationRecord
  class Access < Collaboration
    class Edit < Access
      # optional is true, as its instance of collaborator relation, defined in collaboration
      belongs_to :editor, polymorphic: true, foreign_type: "collaborator_type", foreign_key: :collaborator_id, optional: true
      belongs_to :added_by_user, class_name: :User, optional: true

      validates :message, presence: true, if: :include_message,     on: :add_editor
      validates :added_by_user_id, presence: true,                  on: :add_editor
      validates :include_message, inclusion: { in: [true, false] }, on: :add_editor

      attr_reader :include_message

      def include_message=(value)
        @include_message = if value.is_a? String
                             (value == "true")
                           else
                             value
                           end
      end

      def own!(_investigation)
        collaborator.own!(investigation)
      end
    end
  end
end
