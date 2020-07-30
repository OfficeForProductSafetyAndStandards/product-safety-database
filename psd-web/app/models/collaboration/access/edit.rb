class Collaboration < ApplicationRecord
  class Access < Collaboration
    class Edit < Access
      belongs_to :added_by_user, class_name: :User, optional: true

      def own!(_investigation)
        destroy!
        collaborator.own!(investigation)
      end

      def self.changeable?
        true
      end
    end
  end
end
