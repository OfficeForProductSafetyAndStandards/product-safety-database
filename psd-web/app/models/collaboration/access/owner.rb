class Collaboration < ApplicationRecord
  class Access < Collaboration
    class Owner < Edit; end
  end
end
