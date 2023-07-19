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

    enum product_aimed_at: {
      "particular_group_of_users" => "particular_group_of_users",
      "general_population" => "general_population",
    }

    validates :number_of_hazards, inclusion: %w[one two three four five more_than_five]
    validates :product_aimed_at, inclusion: %w[particular_group_of_users general_population]
    validates :product_aimed_at_description, presence: true, if: -> { product_aimed_at == "particular_group_of_users" }
    validates :unintended_risks_for, array_intersection: { in: %w[unintended_users non_users] }

    before_save :clear_product_aimed_at_description

  private

    def clear_product_aimed_at_description
      self.product_aimed_at_description = nil unless product_aimed_at == "particular_group_of_users"
    end
  end
end
