# This migration comes from prism (originally 20230913132741)
class CreatePrismAssociatedProducts < ActiveRecord::Migration[7.0]
  def change
    safety_assured do
      create_table :prism_associated_products, id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
        t.references :risk_assessment, type: :uuid
        t.references :product
        t.timestamps
      end
    end
  end
end
