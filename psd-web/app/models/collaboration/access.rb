class Collaboration < ApplicationRecord
  class Access < Collaboration
    require_dependency "collaboration/access/read_only"
    require_dependency "collaboration/access/edit"

  end
end
