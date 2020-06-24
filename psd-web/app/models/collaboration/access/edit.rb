class Collaboration < ApplicationRecord
  class Access < Collaboration
    class Edit < Access
      belongs_to :added_by_user, class_name: :User, optional: true

      validates :message, presence: true, if: :include_message,     on: :add_editor
      validates :added_by_user_id, presence: true,                  on: :add_editor
      validates :include_message, inclusion: { in: [true, false] }, on: :add_editor

      attribute :include_message, :boolean, default: false

      def own!(_investigation)
        collaborator.own!(investigation)
      end
    end
  end
end
