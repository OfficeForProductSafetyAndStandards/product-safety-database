# This migration comes from prism (originally 20230918155754)
class RemoveOtherSafetyLegislationStandardFromPrismProductMarketDetails < ActiveRecord::Migration[7.0]
  def change
    safety_assured do
      remove_column :prism_product_market_details, :other_safety_legislation_standard, :string
    end
  end
end
