class Collaboration < ApplicationRecord
  class Access < Collaboration
    class Owner < Edit
      def self.can_be_changed?
        false
      end
    end
  end
end
