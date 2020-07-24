class Collaboration < ApplicationRecord
  class Access < Collaboration
    class ReadOnly < Access
      belongs_to :added_by_user, class_name: :User, optional: true

      def self.can_be_changed?
        true
      end
    end
  end
end
