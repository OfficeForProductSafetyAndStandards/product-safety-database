module Prism
  class Product < ApplicationRecord
    belongs_to :risk_assessment

    enum has_markings: {
      "yes" => "yes",
      "no" => "no",
      "unknown" => "unknown",
    }
  end
end
