class Collaboration < ApplicationRecord
  class Access < Collaboration
    class Owner < Edit; end
    attribute :include_message, :boolean, default: false
  end
end
