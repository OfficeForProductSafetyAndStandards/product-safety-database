class Collaboration < ApplicationRecord
  class Access < Collaboration
    class OwnerUser < Owner; end
  end
end
