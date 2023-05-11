module Prism
  class ProductHazard < ApplicationRecord
    belongs_to :risk_assessment

    enum number_of_hazards: {
      "one" => "one",
      "two" => "two",
      "three" => "three",
      "four" => "four",
      "five" => "five",
      "more_than_five" => "more_than_five",
    }
  end
end
