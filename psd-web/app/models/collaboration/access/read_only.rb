class Collaboration < ApplicationRecord
  class Access < Collaboration
    class ReadOnly < Access; end
  end
end
