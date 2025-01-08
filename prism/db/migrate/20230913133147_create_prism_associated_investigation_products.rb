class CreatePrismAssociatedInvestigationProducts < ActiveRecord::Migration[7.0]
  def change
    safety_assured do
      create_table :prism_associated_investigation_products, id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
        t.references :associated_investigation, type: :uuid, index: { name: "index_prism_associated_products_on_associated_investigation_id" }
        t.references :product
        t.timestamps
      end
    end
  end
end
