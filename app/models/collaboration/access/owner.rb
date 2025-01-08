class Collaboration < ApplicationRecord
  class Access < Collaboration
    class Owner < Edit
      def self.changeable?
        false
      end
    end
  end
end
