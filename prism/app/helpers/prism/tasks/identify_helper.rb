module Prism
  module Tasks::IdentifyHelper
    def number_of_hazards_radios
      [
        OpenStruct.new(id: "one", name: "1"),
        OpenStruct.new(id: "two", name: "2"),
        OpenStruct.new(id: "three", name: "3"),
        OpenStruct.new(id: "four", name: "4"),
        OpenStruct.new(id: "five", name: "5"),
        OpenStruct.new(id: "more_than_five", name: "More than 5"),
      ]
    end
  end
end
