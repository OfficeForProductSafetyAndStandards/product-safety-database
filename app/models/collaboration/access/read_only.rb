class Collaboration < ApplicationRecord
  class Access < Collaboration
    class ReadOnly < Access
      belongs_to :added_by_user, class_name: :User, optional: true
      include ChangeableTeam
    end
  end
end
