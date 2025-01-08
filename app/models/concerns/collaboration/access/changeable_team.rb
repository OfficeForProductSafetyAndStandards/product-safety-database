class Collaboration < ApplicationRecord
  class Access < Collaboration
    module ChangeableTeam
      extend ActiveSupport::Concern

      included do
        def self.changeable?
          true
        end
      end

      def own!(_investigation)
        destroy!
        collaborator.own!(investigation)
      end
    end
  end
end
