module Prism
  class Product < ApplicationRecord
    belongs_to :risk_assessment

    enum placed_on_market_before_eu_exit: {
      "yes" => "yes",
      "no" => "no",
      "unknown" => "unknown",
    }
  end
end
