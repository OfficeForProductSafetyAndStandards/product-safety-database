class AddDefaultArrayToStandardsProductWasTestedAgainst < ActiveRecord::Migration[6.0]
  def change
    safety_assured do
      change_column_default :tests, :standards_product_was_tested_against, from: nil, to: []
    end
  end
end
