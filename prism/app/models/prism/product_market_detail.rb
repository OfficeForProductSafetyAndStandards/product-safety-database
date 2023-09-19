require "store_attribute"

module Prism
  class ProductMarketDetail < ApplicationRecord
    belongs_to :risk_assessment

    store_attribute :routing_questions, :total_products_sold_estimatable, :boolean

    validates :selling_organisation, presence: true
    validates :total_products_sold_estimatable, inclusion: [true, false]
    validates :total_products_sold, presence: true, numericality: { only_integer: true }, if: -> { total_products_sold_estimatable }
    validates :safety_legislation_standards, presence: true, array_intersection: { in: Rails.application.config.legislation_constants["legislation"] }

    before_save :clear_total_products_sold

  private

    def clear_total_products_sold
      self.total_products_sold = nil unless total_products_sold_estimatable
    end
  end
end
