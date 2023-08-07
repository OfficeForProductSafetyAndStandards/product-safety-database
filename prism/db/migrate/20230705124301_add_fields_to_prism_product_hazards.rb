class AddFieldsToPrismProductHazards < ActiveRecord::Migration[7.0]
  def change
    safety_assured do
      change_table :prism_product_hazards, bulk: true do |t|
        t.remove :unintended_risks_for, type: :string

        t.string :product_aimed_at_description
        t.string :unintended_risks_for, array: true, default: []
      end
    end
  end
end
