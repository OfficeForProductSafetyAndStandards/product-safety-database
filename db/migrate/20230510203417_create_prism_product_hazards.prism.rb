# This migration comes from prism (originally 20230510203307)
class CreatePrismProductHazards < ActiveRecord::Migration[7.0]
  def change
    safety_assured do
      create_table :prism_product_hazards, id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
        t.references :prism_risk_assessment
        t.string :number_of_hazards
        t.string :product_aimed_at
        t.string :unintended_risks_for
        t.timestamps
      end
    end
  end
end
