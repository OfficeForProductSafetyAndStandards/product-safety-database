require "store_attribute"

module Prism
  class ProductMarketDetail < ApplicationRecord
    belongs_to :risk_assessment

    store_attribute :routing_questions, :total_products_sold_estimatable, :boolean

    validates :selling_organisation, presence: true
    validates :total_products_sold_estimatable, inclusion: [true, false]
    validates :total_products_sold, presence: true, numericality: { only_integer: true }, if: -> { total_products_sold_estimatable }
    validates :safety_legislation_standards, presence: true, array_intersection: { in: %w[regulation_4404 regulation_129 bs_en_17072_2018 bs_en_17022_2018 other] }
    validates :other_safety_legislation_standard, presence: true, if: -> { safety_legislation_standards.include?("other") }

    before_save :clear_total_products_sold
    before_save :clear_other_safety_legislation_standard

  private

    def clear_total_products_sold
      self.total_products_sold = nil unless total_products_sold_estimatable
    end

    def clear_other_safety_legislation_standard
      self.other_safety_legislation_standard = nil unless safety_legislation_standards.include?("other")
    end
  end
end
