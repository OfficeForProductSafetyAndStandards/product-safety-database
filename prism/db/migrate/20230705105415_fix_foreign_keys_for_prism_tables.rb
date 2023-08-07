class FixForeignKeysForPrismTables < ActiveRecord::Migration[7.0]
  def change
    safety_assured do
      change_table :prism_products, bulk: true do |t|
        t.remove_references :prism_risk_assessment

        t.references :risk_assessment, type: :uuid
      end

      change_table :prism_product_market_details, bulk: true do |t|
        t.remove_references :prism_risk_assessment

        t.references :risk_assessment, type: :uuid
      end

      change_table :prism_product_hazards, bulk: true do |t|
        t.remove_references :prism_risk_assessment

        t.references :risk_assessment, type: :uuid
      end

      change_table :prism_harm_scenarios, bulk: true do |t|
        t.remove_references :prism_risk_assessment

        t.references :risk_assessment, type: :uuid
      end
    end
  end
end
